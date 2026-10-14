import SwiftUI

/// Floating quick-log control (F4). A glass button that morphs into a glass text field.
/// Glass sits on the control layer only, the content under it stays plain.
struct QuickLogBar: View {
    @Bindable var model: QuickLogModel
    let onSubmit: () -> Void

    @Namespace private var glassNamespace
    @State private var isExpanded = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if isExpanded, let message = AIAvailability.unavailableMessage {
                Text(message)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 12) {
                    if isExpanded {
                        TextField("žlutá 6c v převisu, RP", text: $model.text)
                            .textFieldStyle(.plain)
                            .focused($isFieldFocused)
                            .submitLabel(.send)
                            .onSubmit(submit)
                            .padding(.horizontal, 18)
                            .frame(height: 52)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .glassEffectID("field", in: glassNamespace)
                    }
                    Button(action: buttonTapped) {
                        Group {
                            if model.isResolving {
                                ProgressView()
                            } else {
                                Image(systemName: isExpanded ? "arrow.up" : "sparkles")
                                    .font(.title2.weight(.semibold))
                            }
                        }
                        .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
                    .glassEffectID("action", in: glassNamespace)
                    .accessibilityLabel(isExpanded ? "Najít cestu" : "Rychlý zápis")
                }
            }
        }
        .padding()
        .onChange(of: model.interpretation == nil) { _, isCleared in
            if isCleared, model.text.isEmpty { collapse() }
        }
    }

    private func buttonTapped() {
        if isExpanded {
            if model.text.trimmingCharacters(in: .whitespaces).isEmpty {
                collapse()
            } else {
                submit()
            }
        } else {
            withAnimation(.bouncy) { isExpanded = true }
            isFieldFocused = true
        }
    }

    private func submit() {
        isFieldFocused = false
        onSubmit()
    }

    private func collapse() {
        withAnimation(.bouncy) { isExpanded = false }
    }
}
