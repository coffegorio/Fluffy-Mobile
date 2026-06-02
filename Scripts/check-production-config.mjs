import { readFileSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const failures = [];

const apiConfig = readFileSync(resolve(root, "Fluffy/Services/API/APIConfiguration.swift"), "utf8");
const releaseBaseURL = apiConfig.match(/#else\s*return APIConfiguration\(baseURL:\s*URL\(string:\s*"([^"]+)"\)!\)/m)?.[1];

if (!releaseBaseURL) {
  failures.push("Release API base URL fallback was not found in APIConfiguration.swift.");
} else {
  const url = new URL(releaseBaseURL);
  if (url.protocol !== "https:") {
    failures.push(`Release API base URL must use HTTPS, got ${releaseBaseURL}.`);
  }
  if (["localhost", "127.0.0.1", "::1"].includes(url.hostname)) {
    failures.push(`Release API base URL must not point to a local host, got ${releaseBaseURL}.`);
  }
}

const project = readFileSync(resolve(root, "Fluffy.xcodeproj/project.pbxproj"), "utf8");
if (!/DBCED7CE2F9A0F9A0084CF3F \/\* Debug \*\/[\s\S]*?APS_ENVIRONMENT = development;/.test(project)) {
  failures.push("Debug build configuration must use APS_ENVIRONMENT = development.");
}
if (!/DBCED7CF2F9A0F9A0084CF3F \/\* Release \*\/[\s\S]*?APS_ENVIRONMENT = production;/.test(project)) {
  failures.push("Release build configuration must use APS_ENVIRONMENT = production.");
}

const entitlements = readFileSync(resolve(root, "Fluffy/Fluffy.entitlements"), "utf8");
if (!entitlements.includes("<key>aps-environment</key>") || !entitlements.includes("<string>$(APS_ENVIRONMENT)</string>")) {
  failures.push("Push entitlement must be driven by the APS_ENVIRONMENT build setting.");
}

const infoPlist = readFileSync(resolve(root, "FluffyInfo.plist"), "utf8");
for (const requiredKey of [
  "CFBundleDisplayName",
  "NSPhotoLibraryUsageDescription",
  "ITSAppUsesNonExemptEncryption"
]) {
  if (!infoPlist.includes(`<key>${requiredKey}</key>`)) {
    failures.push(`FluffyInfo.plist must include ${requiredKey}.`);
  }
}
if (!/<key>ITSAppUsesNonExemptEncryption<\/key>\s*<false\/>/.test(infoPlist)) {
  failures.push("FluffyInfo.plist must declare ITSAppUsesNonExemptEncryption as false for standard platform encryption.");
}

const webSocketService = readFileSync(resolve(root, "Fluffy/Services/Marketplace/WebSocketService.swift"), "utf8");
if (/URLQueryItem\s*\(\s*name:\s*"token"/.test(webSocketService)) {
  failures.push("WebSocket access tokens must be sent in the Authorization header, not as URL query items.");
}
if (!/forHTTPHeaderField:\s*"Authorization"/.test(webSocketService)) {
  failures.push("WebSocket requests must set an Authorization header.");
}

const mediaService = readFileSync(resolve(root, "Fluffy/Services/Media/MediaService.swift"), "utf8");
if (!mediaService.includes('"/api/v1/media/complete"')) {
  failures.push("Signed media uploads must call /api/v1/media/complete after successful PUT.");
}
if (!/try\s+await\s+upload\(data:[\s\S]*try\s+await\s+complete\(mediaId:/.test(mediaService)) {
  failures.push("Media completion must happen only after the signed upload succeeds.");
}

const apiClient = readFileSync(resolve(root, "Fluffy/Services/API/APIClient.swift"), "utf8");
if (!apiClient.includes('"verification_required"')) {
  failures.push("iOS must map backend verification_required errors to a user-facing message.");
}

const marketplaceService = readFileSync(resolve(root, "Fluffy/Services/Marketplace/APIMarketplaceService.swift"), "utf8");
if (!/func\s+registerPushDevice\([^)]*environment:\s*PushEnvironment/.test(marketplaceService) || !/environment:\s*environment\.rawValue/.test(marketplaceService)) {
  failures.push("Push device registration must send the selected APNs environment to the backend.");
}
if (!/let\s+lastMessageAt:\s*Date\?/.test(marketplaceService) || !/lastMessageAt\s*\?\?\s*updatedAt\s*\?\?\s*createdAt/.test(marketplaceService)) {
  failures.push("Chat list timestamps must prefer backend lastMessageAt over chat updatedAt/createdAt.");
}
if (!/let\s+listingTitle:\s*String\?/.test(marketplaceService) || !/let\s+otherParticipantName:\s*String\?/.test(marketplaceService)) {
  failures.push("Chat list mapping must consume backend summary fields instead of depending on public listing detail.");
}
const fetchConversationsMatch = marketplaceService.match(/func\s+fetchConversations\(\)\s+async\s+throws\s+->\s+\[Conversation\]\s*\{[\s\S]*?\n\s*\}/);
if (!fetchConversationsMatch || /\/api\/v1\/chats\/\\\(chat\.id\)\/messages/.test(fetchConversationsMatch[0])) {
  failures.push("Chat list loading must not fetch every conversation's messages; load messages lazily for the opened chat.");
}
if (!fetchConversationsMatch || /fetchListingIfNeeded/.test(fetchConversationsMatch[0])) {
  failures.push("Chat list loading must use backend chat summary fields, not public listing detail requests.");
}
if (!/func\s+fetchMessages\(conversationID:\s*String\)\s+async\s+throws\s+->\s+\[ChatMessage\]/.test(marketplaceService)) {
  failures.push("Marketplace service must expose lazy chat message loading.");
}

const mainViewModel = readFileSync(resolve(root, "Fluffy/Screens/Main/MainViewModel.swift"), "utf8");
if (!/loadConversationMessagesIfNeeded/.test(mainViewModel) || !/mergeConversationSummaries/.test(mainViewModel)) {
  failures.push("MainViewModel must lazily load chat messages while preserving loaded history during chat list refresh.");
}

const appCoordinator = readFileSync(resolve(root, "Fluffy/App/AppCoordinator.swift"), "utf8");
if (!/#if DEBUG\s*\.sandbox\s*#else\s*\.production\s*#endif/.test(appCoordinator)) {
  failures.push("iOS push registration must use sandbox only for DEBUG and production for Release.");
}

const authSessionStore = readFileSync(resolve(root, "Fluffy/Services/Auth/AuthSessionStore.swift"), "utf8");
if (!authSessionStore.includes("kSecAttrAccessibleWhenUnlockedThisDeviceOnly")) {
  failures.push("Refresh sessions must use Keychain accessibility WhenUnlockedThisDeviceOnly.");
}
if (authSessionStore.includes("kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly")) {
  failures.push("Refresh sessions must not remain accessible while the device is locked after first unlock.");
}

const productionSourceFiles = [
  "Fluffy/App",
  "Fluffy/Models",
  "Fluffy/Screens",
  "Fluffy/Services"
];
for (const relativePath of productionSourceFiles) {
  const files = [];
  collectSwiftFiles(resolve(root, relativePath), files);
  for (const file of files) {
    const source = readFileSync(file, "utf8");
    if (/\bprint\s*\(/.test(source)) {
      failures.push(`Production Swift source must use Logger instead of print(): ${file.replace(`${root}/`, "")}`);
    }
  }
}

if (failures.length > 0) {
  console.error(failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}

console.log(`Production config check passed: Release API ${releaseBaseURL}, APNs environments are split by configuration.`);

function collectSwiftFiles(directory, files) {
  for (const entry of readdirSync(directory)) {
    const fullPath = resolve(directory, entry);
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      collectSwiftFiles(fullPath, files);
    } else if (entry.endsWith(".swift")) {
      files.push(fullPath);
    }
  }
}
