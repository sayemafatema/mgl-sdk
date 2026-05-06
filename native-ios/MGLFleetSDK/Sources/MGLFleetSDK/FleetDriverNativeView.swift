import SwiftUI

/// Native parity shell for repo `app/page.tsx` flows (OTP 123456, PIN 123456, pairing `234567`, etc.).
struct FleetDriverNativeView: View {
    var onFinish: (FleetSdkResult) -> Void

    @State private var onboardingStep = "login"
    @State private var isRegistered = true
    @State private var mobile = ""
    @State private var otpDigits = Array(repeating: "", count: 6)
    @State private var otpError = ""
    @State private var forgotOtpDigits = Array(repeating: "", count: 6)
    @State private var rstPin = ""
    @State private var rstPinConfirm = ""
    @State private var rstPinError = ""
    @State private var loginPin = ""
    @State private var loginPinError = ""
    @State private var wrongAttempts = 0
    @State private var mainTab = 0
    @State private var activeCard = 0
    @State private var overlay: String = "none"
    @State private var inviteField = ""
    @State private var pairingField = ""
    @State private var pairingError = ""
    @State private var pairingAttempts = 0
    @State private var pairingSuccess = false
    @State private var sessionPhase = "idle"
    @State private var sessionPin = ""
    @State private var showPairingHelp = false

    private let driver = FleetReactMockIOS.driver

    private var activeCards: [DemoBinding] {
        FleetReactMockIOS.bindings.filter { $0.paired && $0.state == .active }
    }

    private var pairingAssignment: DemoBinding { FleetReactMockIOS.assignmentForPairing }

    var body: some View {
        Group {
            if onboardingStep != "complete" {
                onboarding
            } else {
                mainShell
            }
        }
    }

    private var onboarding: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    stepContent
                }
                .padding()
            }

            Menu {
                Button("Skip to Main App") { onboardingStep = "complete" }
                Button(isRegistered ? "Mode: returning user ✓" : "Mode: new user ✓") {
                    isRegistered.toggle()
                }
            } label: {
                Text("⋮")
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .padding()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch onboardingStep {
        case "login":
            loginStep
        case "login_otp":
            otpStep(digits: $otpDigits, error: otpError, back: "login") {
                otpError = ""
                let s = otpDigits.joined()
                if s == "123456" {
                    onboardingStep = isRegistered ? "complete" : "set_pin_first"
                } else {
                    otpError = "Incorrect OTP."
                }
            }
        case "pin_login":
            pinLoginStep
        case "forgot_pin":
            forgotPinIntro
        case "forgot_otp":
            otpStep(digits: $forgotOtpDigits, error: "", back: "forgot_pin") {
                if forgotOtpDigits.joined() == "123456" {
                    rstPin = ""
                    rstPinConfirm = ""
                    rstPinError = ""
                    onboardingStep = "set_pin_reset"
                }
            }
        case "set_pin_reset":
            pinReset(title: "Create new PIN", pin: $rstPin, onNext: {
                if rstPin.count == 6 { onboardingStep = "confirm_pin_reset" }
            })
        case "confirm_pin_reset":
            pinReset(title: "Confirm new PIN", pin: $rstPinConfirm, hint: rstPinError, onNext: {
                if rstPinConfirm == rstPin {
                    rstPinError = ""
                    rstPin = ""
                    rstPinConfirm = ""
                    loginPin = ""
                    loginPinError = ""
                    wrongAttempts = 0
                    onboardingStep = "pin_login"
                } else {
                    rstPinError = "PINs don't match."
                    rstPinConfirm = ""
                }
            })
        case "set_pin_first":
            pinReset(title: "Create your PIN", pin: $rstPin, onNext: {
                if rstPin.count == 6 { onboardingStep = "confirm_pin_first" }
            })
        case "confirm_pin_first":
            pinReset(title: "Confirm your PIN", pin: $rstPinConfirm, hint: rstPinError, onNext: {
                if rstPinConfirm == rstPin {
                    onboardingStep = "complete"
                } else {
                    rstPinError = "PIN mismatch"
                    rstPinConfirm = ""
                }
            })
        case "invite":
            inviteStep
        default:
            EmptyView()
        }
    }

    private var loginStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MGL Fleet Connect").font(.title2).bold()
            Text("Driver App").font(.caption).foregroundStyle(.secondary)
            Text("Mobile").font(.caption)
            TextField(
                "10-digit mobile",
                text: Binding(
                    get: { mobile },
                    set: { mobile = String($0.filter(\.isNumber).prefix(10)) },
                ),
            )
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            Button("Send OTP") {
                otpDigits = Array(repeating: "", count: 6)
                otpError = ""
                onboardingStep = "login_otp"
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
            .disabled(mobile.count != 10)

            Button("Returning user · PIN login") {
                loginPin = ""
                loginPinError = ""
                onboardingStep = "pin_login"
            }
            .buttonStyle(.bordered)

            Button("New user — invite code") {
                inviteField = ""
                onboardingStep = "invite"
            }
            .buttonStyle(.bordered)
        }
    }

    private func otpStep(
        digits: Binding<[String]>,
        error: String,
        back: String,
        onVerify: @escaping () -> Void,
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("< Back") {
                onboardingStep = back
            }
            .buttonStyle(.plain)
            Text("Verify mobile").font(.title3).bold()
            HStack(spacing: 8) {
                ForEach(0 ..< 6, id: \.self) { i in
                    TextField(
                        "",
                        text: Binding(
                            get: { digits.wrappedValue[i] },
                            set: {
                                var d = digits.wrappedValue
                                d[i] = String($0.filter(\.isNumber).suffix(1))
                                digits.wrappedValue = d
                            },
                        ),
                    )
                    .frame(width: 36)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                }
            }
            if !error.isEmpty { Text(error).foregroundStyle(.red).font(.caption) }
            Button("Verify", action: onVerify)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
                .disabled(digits.wrappedValue.joined().count != 6)
        }
    }

    private var pinLoginStep: some View {
        VStack(spacing: 12) {
            Text("Welcome back").font(.caption).foregroundStyle(.secondary)
            Text(driver.name).font(.title2).bold()
            SecureField(
                "6-digit PIN",
                text: Binding(
                    get: { loginPin },
                    set: {
                        loginPin = String($0.filter(\.isNumber).prefix(6))
                        loginPinError = ""
                    },
                ),
            )
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            if !loginPinError.isEmpty { Text(loginPinError).font(.caption).foregroundStyle(.red) }
            Button("Continue") {
                if loginPin == driver.pin {
                    onboardingStep = "complete"
                } else {
                    wrongAttempts += 1
                    loginPinError = "Incorrect PIN"
                    loginPin = ""
                }
            }
            .disabled(loginPin.count != 6 || wrongAttempts >= 3)

            Button("Forgot PIN?") {
                onboardingStep = "forgot_pin"
            }

            if wrongAttempts >= 3 {
                Text("Too many attempts. Reset via OTP.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var forgotPinIntro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("< Back") { onboardingStep = "pin_login" }
                .buttonStyle(.plain)
            Text("Reset your PIN").font(.title3).bold()
            Text("Verify via OTP on your registered number.").font(.caption).foregroundStyle(.secondary)
            Text(driver.mobile.maskedIndian).padding().frame(maxWidth: .infinity).background(Color(.secondarySystemFill)).clipShape(RoundedRectangle(cornerRadius: 12))
            Button("Send OTP") {
                forgotOtpDigits = Array(repeating: "", count: 6)
                onboardingStep = "forgot_otp"
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
        }
    }

    private func pinReset(title: String, pin: Binding<String>, hint: String = "", onNext: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3).bold()
            if !hint.isEmpty { Text(hint).foregroundStyle(.red).font(.caption) }
            SecureField("PIN", text: pin)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .disabled(pin.wrappedValue.count != 6)
        }
    }

    private var inviteStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("< Back") { onboardingStep = "login" }
                .buttonStyle(.plain)
            Text("Invite code").font(.title3).bold()
            TextField(
                "ABC123",
                text: Binding(
                    get: { inviteField },
                    set: { inviteField = String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6)) },
                ),
            )
            .textFieldStyle(.roundedBorder)
            if FleetReactMockIOS.inviteCodes[inviteField] != nil {
                Text(FleetReactMockIOS.inviteCodes[inviteField] ?? "").font(.caption).padding(8).background(Color.green.opacity(0.15))
            }
            Button("Continue") {
                if FleetReactMockIOS.inviteCodes[inviteField] != nil { onboardingStep = "complete" }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inviteField.count != 6 || FleetReactMockIOS.inviteCodes[inviteField] == nil)
        }
    }

    private var mainShell: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                Group {
                    switch mainTab {
                    case 0: cardTab
                    case 1: scanTab
                    case 2: assignmentsSectioned
                    default: profileTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                HStack {
                    tabBtn(0, "Home")
                    tabBtn(1, "Scan")
                    tabBtn(2, "Assignments")
                    tabBtn(3, "Profile")
                }
                .padding(.vertical, 8)
            }

            overlayContent
        }
        .sheet(isPresented: $showPairingHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pairing code help").font(.headline)
                Text("Ask your Fleet Operator for the 6-digit pairing code. They can find it in the MGL Fleet portal under Driver Management.")
                    .font(.subheadline)
                Button("OK") { showPairingHelp = false }
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch overlay {
        case "assignment":
            assignmentOverlay
        case "pairing":
            pairingOverlay
        case "accepted":
            assignmentAccepted
        default:
            EmptyView()
        }
    }

    private var assignmentOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { overlay = "none" } label: { Image(systemName: "chevron.left") }
                Spacer()
            }
            Text(pairingAssignment.vrn).font(.largeTitle).bold().monospaced()
            Text(pairingAssignment.fo)
            Text("Pairing required — enter the code from your Fleet Operator.")
                .font(.subheadline)
                .padding()
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button("Accept & Pair") {
                pairingField = ""
                pairingError = ""
                pairingAttempts = 0
                pairingSuccess = false
                overlay = "pairing"
            }
            .buttonStyle(.borderedProminent)
            Button("Close") { overlay = "none" }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var pairingOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    overlay = "assignment"
                    pairingField = ""
                } label: { Image(systemName: "chevron.left") }
                Text("Enter pairing code").font(.headline)
                Spacer()
            }
            Text(pairingAssignment.vrn).font(.title2).bold().monospaced()
            TextField(
                "6 digits",
                text: Binding(
                    get: { pairingField },
                    set: {
                        pairingField = String($0.filter(\.isNumber).prefix(6))
                        pairingError = ""
                    },
                ),
            )
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            if pairingSuccess {
                Label("Pairing successful!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if !pairingError.isEmpty, !pairingSuccess {
                Text(pairingError).foregroundStyle(.red).font(.caption)
            }
            if pairingAttempts >= 3 {
                Text("Too many attempts. Ask your Fleet Operator for a new code.")
                    .font(.caption)
                Button("Close") { overlay = "none"; pairingAttempts = 0 }
            } else if !pairingSuccess {
                Button("Verify & Activate") {
                    if pairingField == pairingAssignment.validPairingCode ?? "" {
                        pairingSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            pairingSuccess = false
                            pairingField = ""
                            pairingAttempts = 0
                            overlay = "accepted"
                        }
                    } else {
                        pairingAttempts += 1
                        pairingError = "Incorrect code."
                        pairingField = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(pairingField.count != 6)
            }
            Button("Haven't received your code?") { showPairingHelp = true }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var assignmentAccepted: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("Assignment activated!")
                .font(.title2).bold()
                .foregroundStyle(.green)
            Text(pairingAssignment.vrn).font(.title3).bold().monospaced()
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.green.opacity(0.15)).clipShape(Capsule())
            Text("What's now unlocked: Scan & Pay for this assignment after pairing succeeds in production.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Go to My Assignments") {
                overlay = "none"
                mainTab = 2
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color.green.opacity(0.12), Color(.systemBackground)], startPoint: .top, endPoint: .bottom),
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Good morning").font(.caption).foregroundStyle(.secondary)
                Text(driver.name).font(.title3).bold()
            }
            Spacer()
            Text(driver.initials)
                .bold()
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 5 / 255, green: 150 / 255, blue: 105 / 255))
        .foregroundStyle(.white)
    }

    private var cardTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button("Open assignment (demo)") { overlay = "assignment" }
                    .font(.caption)
                let cards = activeCards
                let idx = min(activeCard, max(cards.count - 1, 0))
                if let c = cards[safe: idx] {
                    Text(c.fo).font(.caption).foregroundStyle(.secondary)
                    Text(c.vrn).font(.title).bold().monospaced()
                    Text("₹\(c.balance)").font(.largeTitle).bold()
                    Button("Scan & Pay") { mainTab = 1 }
                        .buttonStyle(.borderedProminent)
                    HStack {
                        ForEach(Array(cards.enumerated()), id: \.offset) { i, _ in
                            Circle()
                                .fill(i == idx ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .onTapGesture { activeCard = i }
                        }
                    }
                }
                ForEach(FleetReactMockIOS.transactions) { t in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(t.station).bold()
                            Text(t.date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("-₹\(t.amount)").foregroundStyle(.red)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }

    private var scanTab: some View {
        Group {
            if sessionPhase == "idle" {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "qrcode")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    Button("Simulate Scan") { sessionPhase = "pin" }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if sessionPhase == "pin" {
                Text("Confirm — enter PIN").font(.headline)
                SecureField(
                    "PIN",
                    text: Binding(
                        get: { sessionPin },
                        set: { sessionPin = String($0.filter(\.isNumber).prefix(6)) },
                    ),
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                Button("Verify") {
                    if sessionPin == driver.pin { sessionPhase = "done" } else { sessionPin = "" }
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel") { sessionPhase = "idle"; sessionPin = "" }
            } else {
                Text("Fueling authorized").font(.title2).bold()
                Button("Done") {
                    sessionPhase = "idle"
                    sessionPin = ""
                    mainTab = 0
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var assignmentsSectioned: some View {
        let binds = FleetReactMockIOS.bindings
        let active = binds.filter { $0.paired && $0.state == .active }
        let pend = binds.filter { $0.state == .pendingAcceptance }
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("My Assignments").font(.title2).bold()
                Text("\(active.count) active · \(pend.count) pending").font(.caption).foregroundStyle(.secondary)

                sectionTitle("ACTIVE")
                ForEach(active) { b in
                    FleetAssignmentRow(binding: b)
                }

                if !pend.isEmpty {
                    sectionTitle("PENDING")
                    ForEach(pend) { b in
                        FleetAssignmentRow(binding: b, amber: true)
                    }
                }
            }
            .padding()
        }
    }

    private var profileTab: some View {
        VStack(spacing: 16) {
            Text(driver.name).font(.title2).bold()
            Text("DRV · \(driver.id)").font(.caption).foregroundStyle(.secondary)
            Button("Logout") {
                onFinish(.success(event: "FLEET_FLOW_COMPLETED", payload: ["reason": "logout"]))
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func tabBtn(_ i: Int, _ label: String) -> some View {
        Button(label) {
            mainTab = i
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
        .foregroundStyle(mainTab == i ? Color.green : Color.gray)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}

private struct FleetAssignmentRow: View {
    let binding: DemoBinding
    var amber: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(binding.vrn).font(.headline.monospaced())
            Text(binding.fo).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(amber ? Color.orange.opacity(0.08) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

private extension String {
    /// "+91 ••••••1234" style demo mask
    var maskedIndian: String {
        let d = filter(\.isNumber)
        guard d.count >= 10 else { return "+91 ••••••" + d.suffix(min(4, d.count)) }
        return "+91 ••••••" + String(d.suffix(4))
    }
}
