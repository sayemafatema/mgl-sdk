import SwiftUI

// MARK: - Colors (Android React parity)

enum FleetParityColors {
    static let green700 = Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255)
    static let green600 = Color(red: 5 / 255, green: 150 / 255, blue: 105 / 255)
    static let gray500 = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
    static let textPrimary = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let textMuted = Color(red: 113 / 255, green: 128 / 255, blue: 150 / 255)
    static let cardBorder = Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)
    static let disabledBg = Color(red: 209 / 255, green: 213 / 255, blue: 219 / 255)
}

func otpBannerLineMobileReactStyle(_ loginDigits10: String) -> String {
    let d = loginDigits10.filter(\.isNumber)
    let last4: String =
        if d.count >= 4 { String(d.suffix(4)) }
        else if d.isEmpty { "••••" }
        else { String(d.padding(toLength: 4, withPad: "•", startingAt: 0)) }
    let maskedCore = String(last4.padding(toLength: 10, withPad: "•", startingAt: 0))
    return "OTP sent to +91 \(maskedCore)"
}

func otpScanBannerLine(_ loginDigits10: String, maskedFromProfile: String?) -> String {
    let m = maskedFromProfile?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if m.isEmpty { return otpBannerLineMobileReactStyle(loginDigits10) }
    return "OTP sent to \(m)"
}

// MARK: - Back row

struct OnboardingBackRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                Text("Back")
                    .font(.system(size: 14))
            }
            .foregroundStyle(FleetParityColors.gray500)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PIN entry

struct PinDotsView: View {
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< 6, id: \.self) { i in
                Circle()
                    .strokeBorder(i < value.count ? FleetParityColors.green700 : Color(0xFFD1D5DB), lineWidth: 2)
                    .background(Circle().fill(i < value.count ? FleetParityColors.green700 : Color.clear))
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.vertical, 16)
    }
}

struct NumpadView: View {
    let enabled: Bool
    let onDigit: (String) -> Void
    let onBackspace: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { d in
                        Button(d) { if enabled { onDigit(d) } }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(FleetParityColors.cardBorder))
                            .disabled(!enabled)
                    }
                }
            }
            HStack(spacing: 8) {
                Button("← Backspace") { if enabled { onBackspace() } }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 254 / 255, green: 226 / 255, blue: 226 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(!enabled)
                Button("0") { if enabled { onDigit("0") } }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(FleetParityColors.cardBorder))
                    .disabled(!enabled)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - OTP fields

struct SixDigitOtpFieldsView: View {
    @Binding var digits: [String]
    var refocusFirstAfterKey: Int = 0
    @FocusState private var focusedIndex: Int?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 6, id: \.self) { i in
                TextField(
                    "",
                    text: Binding(
                        get: { digits[i] },
                        set: { newVal in
                            let filtered = String(newVal.filter(\.isNumber).suffix(1))
                            if filtered.isEmpty {
                                digits[i] = ""
                                if i > 0 { focusedIndex = i - 1 }
                            } else {
                                digits[i] = filtered
                                if i < 5 { focusedIndex = i + 1 }
                            }
                        },
                    ),
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 10).stroke(FleetParityColors.cardBorder))
                .focused($focusedIndex, equals: i)
            }
        }
        .onChange(of: refocusFirstAfterKey) { _, key in
            if key > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    focusedIndex = 0
                }
            }
        }
    }
}

// MARK: - Login OTP

struct LoginOtpParityView: View {
    let mobileNumber: String
    @Binding var otpDigits: [String]
    let otpError: String
    let otpCountdown: Int
    let refocusKey: Int
    let isVerifying: Bool
    let isResending: Bool
    let onBack: () -> Void
    let onResend: () -> Void
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingBackRow(action: onBack)
            Text("Verify mobile")
                .font(.title3.bold())
                .foregroundStyle(FleetParityColors.textPrimary)
                .padding(.top, 8)
            Text(otpBannerLineMobileReactStyle(mobileNumber))
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 239 / 255, green: 246 / 255, blue: 255 / 255))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 191 / 255, green: 219 / 255, blue: 254 / 255)))
                .padding(.top, 8)
            SixDigitOtpFieldsView(digits: $otpDigits, refocusFirstAfterKey: refocusKey)
                .padding(.top, 24)
            if !otpError.isEmpty {
                Text(otpError).font(.caption).foregroundStyle(.red).padding(.top, 8)
            }
            Button(action: onVerify) {
                Group {
                    if isVerifying {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Verifying…")
                        }
                    } else {
                        Text("Verify").fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(FleetParityColors.green700)
            .disabled(otpDigits.joined().count != 6 || isVerifying || isResending)
            .padding(.top, 12)
            if otpCountdown > 0 {
                Text("Resend OTP in \(otpCountdown)s")
                    .font(.caption)
                    .foregroundStyle(FleetParityColors.gray500)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            } else {
                Button(action: onResend) {
                    Group {
                        if isResending {
                            HStack(spacing: 8) {
                                ProgressView().tint(FleetParityColors.green700)
                                Text("Sending…")
                            }
                        } else {
                            Text("Resend OTP").fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundStyle(FleetParityColors.green700)
                .disabled(isResending || isVerifying)
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Set / confirm PIN

struct SetPinParityView: View {
    let isNewUser: Bool
    let pin: String
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isNewUser ? "Create your PIN" : "Set new PIN")
                .font(.title3.bold())
                .foregroundStyle(FleetParityColors.textPrimary)
            Text(isNewUser ? "You'll use this every time you sign in" : "Choose a new 6-digit PIN")
                .font(.subheadline)
                .foregroundStyle(FleetParityColors.gray500)
                .padding(.top, 8)
            PinDotsView(value: pin)
            NumpadView(enabled: true, onDigit: onDigit, onBackspace: onBackspace)
            Button("Next", action: onNext)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
                .disabled(pin.count != 6)
                .padding(.top, 24)
        }
    }
}

struct ConfirmPinParityView: View {
    let pinConfirm: String
    let pinError: String
    let onDigit: (String) -> Void
    let onBackNavigation: () -> Void
    let onBackspace: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingBackRow(action: onBackNavigation)
            Text("Confirm your PIN")
                .font(.title3.bold())
                .foregroundStyle(FleetParityColors.textPrimary)
                .padding(.top, 8)
            Text("Enter the same PIN again")
                .font(.subheadline)
                .foregroundStyle(FleetParityColors.gray500)
                .padding(.top, 8)
            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundStyle(.red).padding(.bottom, 8)
            }
            PinDotsView(value: pinConfirm)
            NumpadView(enabled: true, onDigit: onDigit, onBackspace: onBackspace)
            Button("Confirm PIN", action: onSubmit)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
                .disabled(pinConfirm.count != 6)
                .padding(.top, 24)
        }
    }
}

struct RegisteredParityView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(FleetParityColors.green600)
            Text("PIN created successfully")
                .font(.title.bold())
                .foregroundStyle(FleetParityColors.green700)
                .multilineTextAlignment(.center)
            Text("You can now use Scan & Pay at any MGL CNG station")
                .font(.subheadline)
                .foregroundStyle(FleetParityColors.gray500)
                .multilineTextAlignment(.center)
            Button("Continue to Home", action: onContinue)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 240 / 255, green: 253 / 255, blue: 244 / 255), .white],
                startPoint: .top,
                endPoint: .bottom,
            ),
        )
    }
}

struct InvitePinSetupParityView: View {
    let pin: String
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Create your PIN").font(.title3.bold())
            PinDotsView(value: pin)
            NumpadView(enabled: true, onDigit: onDigit, onBackspace: onBackspace)
            Button("Next", action: onNext)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
                .disabled(pin.count != 6)
                .padding(.top, 24)
        }
    }
}

struct InvitePinConfirmParityView: View {
    let pinConfirm: String
    let pinError: String
    let isSubmitting: Bool
    let onDigit: (String) -> Void
    let onBackNavigation: () -> Void
    let onBackspace: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingBackRow(action: onBackNavigation)
            Text("Confirm your PIN").font(.title3.bold()).padding(.top, 8)
            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundStyle(.red)
            }
            PinDotsView(value: pinConfirm)
            NumpadView(enabled: !isSubmitting, onDigit: onDigit, onBackspace: onBackspace)
            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Saving…")
                        }
                    } else {
                        Text("Confirm PIN").fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(FleetParityColors.green700)
            .disabled(pinConfirm.count != 6 || isSubmitting)
            .padding(.top, 24)
        }
    }
}

struct ProfileChangePinParityView: View {
    let phase: String
    let pinFirst: String
    let pinSecond: String
    let pinError: String
    let isChanging: Bool
    let onBack: () -> Void
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onPrimary: () -> Void

    private var activePin: String { phase == "first" ? pinFirst : pinSecond }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnboardingBackRow(action: onBack)
            Text(phase == "first" ? "Enter New PIN" : "Confirm New PIN")
                .font(.title3.bold())
            Text(phase == "first"
                ? "Use a 6-digit PIN for payments and sign-in."
                : "Re-enter the same PIN.")
                .font(.caption)
                .foregroundStyle(FleetParityColors.gray500)
            PinDotsView(value: activePin)
            NumpadView(enabled: !isChanging, onDigit: onDigit, onBackspace: onBackspace)
            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundStyle(.red)
            }
            let label =
                isChanging ? "Updating…"
                    : (phase == "first" ? "Confirm PIN" : "Change PIN")
            if phase == "first" {
                Button(label, action: onPrimary)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .tint(FleetParityColors.green700)
                    .disabled(isChanging || pinFirst.count != 6)
            } else {
                Button(label, action: onPrimary)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(FleetParityColors.green700)
                    .disabled(isChanging || pinSecond.count != 6)
            }
        }
        .padding(16)
    }
}
