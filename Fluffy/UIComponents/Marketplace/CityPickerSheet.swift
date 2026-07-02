//
//  CityPickerSheet.swift
//  Fluffy
//

import SwiftUI

struct CityPickerSheet: View {
    let cities: [City]
    let selectedCity: City
    let onSelect: (City) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(cities) { city in
                Button {
                    onSelect(city)
                    dismiss()
                } label: {
                    HStack {
                        Text(city.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()

                        if city.slug == selectedCity.slug {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("Выберите город")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
