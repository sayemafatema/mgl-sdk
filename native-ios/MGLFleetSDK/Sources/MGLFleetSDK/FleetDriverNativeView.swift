import SwiftUI

/// Native parity shell for repo `app/page.tsx` flows (OTP 123456, PIN `234567` pairing demo, driver-app live when `useMock == false`).
struct FleetDriverNativeView: View {
    let options: FleetSdkOptions
    var onFinish: (FleetSdkResult) -> Void
    private let api: DriverAppApiClient

    @State private var onboardingStep = "login"
    @State private var isRegistered = true
    @State private var mobile = ""
    @State private var otpDigits = Array(repeating: "", count: 6)
    @State private var otpError = ""
    @State private var rstPin = ""
    @State private var rstPinConfirm = ""
    @State private var rstPinError = ""
    /// 0 card, 1 scan, 2 assignments, 3 profile, 4 transactions (no bottom-nav highlight; opened from Home View all).
    @State private var mainContent = 0
    @State private var activeCard = 0
    @State private var overlay: String = "none"
    @State private var assignmentPick: DemoBinding?
    @State private var showDeclineConfirm = false
    @State private var detailBinding: DemoBinding?
    @State private var inviteField = ""
    @State private var pairingField = ""
    @State private var pairingError = ""
    @State private var pairingAttempts = 0
    @State private var pairingSuccess = false
    @State private var sessionPhase = "idle"
    @State private var sessionPin = ""
    @State private var sessionOtpDigits = Array(repeating: "", count: 6)
    @State private var showPairingHelp = false
    @State private var sessionIdle = true
    @State private var selectedScan: DemoBinding?
    @State private var parsedScanQr: FleetpayQrPayloadIOS?
    @State private var qrPayBusy = false
    @State private var lastQrPay: QrPayResultParsed?

    @State private var txnFilterIos = "all"
    @State private var scanSessionOtpCountdown = 0
    @State private var loginOtpRefocusKey = 0
    @State private var inviteOtpRefocusKey = 0

    @State private var apiBanner: String?
    @State private var successBanner: String?
    @State private var onboardingAction: String?
    @State private var otpCountdown = 0
    @State private var foScopedToken: String?
    @State private var otpPhaseToken: String?
    @State private var foOrganizationList: [FoListEntryParsed] = []
    @State private var selectedFoCompanyId: Int64?
    @State private var foPinEntry = ""
    @State private var fleetPinFoDisplay = ""

    /** After FO select/unlock (`options.foCompanyId` when bearer-only bootstrap). */
    @State private var persistedFoCompanyId: Int64?
    @State private var foPinSubStep = "enter"
    @State private var forgotFleetPinPhase = "first"
    @State private var forgotFleetPinFirst = ""
    @State private var forgotFleetPinSecond = ""
    @State private var forgotFleetPinError = ""

    @State private var profilePinModalOpen = false
    @State private var profileChangePinPhase = "first"
    @State private var profileChangePinFirst = ""
    @State private var profileChangePinSecond = ""
    @State private var profileChangePinError = ""
    @State private var profilePinChanging = false
    @State private var inviteOtpRef: String?
    @State private var inviteMobileVerificationToken: String?
    @State private var inviteSessionToken: String?
    @State private var validatedInvite: InviteValidateParsed?
    @State private var inviteOtpDigits = Array(repeating: "", count: 6)
    @State private var nuPinInvite = ""
    @State private var nuPinInviteConfirm = ""
    @State private var pinInviteError = ""
    @State private var apiHome: DriverHomeParsed?
    @State private var apiAssignments: [DriverAssignmentParsed] = []
    @State private var apiProfile: DriverProfileParsed?
    @State private var recentLiveTx: [DemoTxn] = []
    @FocusState private var focusedOtpDigitIndex: Int?

    init(onFinish: @escaping (FleetSdkResult) -> Void, options: FleetSdkOptions) {
        self.onFinish = onFinish
        self.options = options
        api = DriverAppApiClient(options: options)
        let skipOnboard = !options.useMock && !(options.authToken?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        _onboardingStep = State(initialValue: skipOnboard ? "complete" : "login")
        _foScopedToken = State(initialValue: skipOnboard ? options.authToken?.trimmingCharacters(in: .whitespacesAndNewlines) : nil)
        _persistedFoCompanyId = State(initialValue: options.useMock ? nil : options.foCompanyId)
    }

    private var effectiveFoCompanyIdForPin: Int64? {
        selectedFoCompanyId ?? persistedFoCompanyId
    }

    private func resetFoForgotLocals() {
        foPinSubStep = "enter"
        forgotFleetPinPhase = "first"
        forgotFleetPinFirst = ""
        forgotFleetPinSecond = ""
        forgotFleetPinError = ""
    }

    private func resetProfilePinModalLocals() {
        profileChangePinPhase = "first"
        profileChangePinFirst = ""
        profileChangePinSecond = ""
        profileChangePinError = ""
        profilePinChanging = false
    }

    private var liveMode: Bool { !options.useMock }

    private var bindingsEffective: [DemoBinding] {
        if liveMode { DriverFleetBindingsMapper.mapAssignmentsToDemoBindings(home: apiHome, rows: apiAssignments) }
        else { FleetReactMockIOS.bindings }
    }

    private var displayDriver: DemoDriver {
        if !liveMode { return FleetReactMockIOS.driver }
        if let p = apiProfile {
            let suf = String(mobile.filter(\.isNumber).suffix(4))
            let filler = String(repeating: "•", count: max(0, 6))
            let mask = "+91 \(filler)" + suf
            return DemoDriver(
                id: p.driverId.isEmpty ? "DRV" : p.driverId,
                name: p.name.isEmpty ? "Driver" : p.name,
                initials: FleetDriverNativeView.initials(of: p.name.isEmpty ? "D" : p.name),
                mobile: mobile.isEmpty ? FleetReactMockIOS.driver.mobile : mobile,
                maskedMobile: p.maskedMobile ?? mask,
                pin: FleetReactMockIOS.driver.pin,
            )
        }
        return FleetReactMockIOS.driver
    }

    private var activeCards: [DemoBinding] {
        bindingsEffective.filter { $0.paired && $0.state == .active }
    }

    private var pairingAssignment: DemoBinding {
        if let pick = assignmentPick { return pick }
        if !liveMode { return FleetReactMockIOS.assignmentForPairing }
        return bindingsEffective.first(where: {
            $0.state == .pendingAcceptance && (
                $0.scanPayStatus == "locked_unpaired" || $0.scanPayStatus == "locked_repair"
            )
        })
        ?? bindingsEffective.first(where: { $0.state == .pendingAcceptance })
        ?? FleetReactMockIOS.assignmentForPairing
    }

    private func scanPayDisabled(_ b: DemoBinding) -> Bool {
        ["out_window", "locked_unpaired", "locked_repair"].contains(b.scanPayStatus)
    }

    private func openAssignmentNotification(_ b: DemoBinding) {
        assignmentPick = b
        overlay = "assignment"
    }

    private func openPairingFor(_ b: DemoBinding) {
        assignmentPick = b
        pairingField = ""
        pairingError = ""
        pairingAttempts = 0
        pairingSuccess = false
        overlay = "pairing"
    }

    private func focusBindingForMain(_ b: DemoBinding) {
        let cards = activeCards
        if let i = cards.firstIndex(where: { $0.id == b.id }) {
            activeCard = i
        }
    }

    private func openScanForBinding(_ b: DemoBinding) {
        focusBindingForMain(b)
        selectedScan = b
        sessionPhase = "idle"
        sessionPin = ""
        sessionOtpDigits = Array(repeating: "", count: 6)
        parsedScanQr = nil
        lastQrPay = nil
        mainContent = 1
        overlay = "none"
    }

    private func openTransactionsForBinding(_ b: DemoBinding) {
        focusBindingForMain(b)
        mainContent = 4
        overlay = "none"
        Task { await loadTransactionsIfNeeded() }
    }

    private var txnSource: [DemoTxn] {
        liveMode ? recentLiveTx : FleetReactMockIOS.transactions
    }

    private var scanEligible: [DemoBinding] {
        bindingsEffective.filter {
            $0.paired && $0.state == .active
                && (["always_available", "in_window", "trip_window"].contains($0.scanPayStatus))
        }
    }

    private var pendingAssignmentCount: Int {
        bindingsEffective.filter {
            $0.state == .pendingAcceptance || (!$0.paired && $0.state == .active)
        }.count
    }

    private func indiaGreeting() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let h = cal.component(.hour, from: Date())
        if (5 ..< 12).contains(h) { return "Good Morning" }
        if (12 ..< 17).contains(h) { return "Good Afternoon" }
        return "Good Evening"
    }

    private func txnStatusSuccess(_ s: String) -> Bool {
        s.caseInsensitiveCompare("SUCCESS") == .orderedSame || s.caseInsensitiveCompare("Success") == .orderedSame
    }

    private func foLine(for card: DemoBinding) -> String {
        let fp = fleetPinFoDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fp.isEmpty { return fp }
        if let n = apiHome?.foName?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
        return card.fo
    }

    private func authBadge(_ m: DemoAuthMode, card: DemoBinding) -> (String, Color, Color) {
        switch m {
        case .vehicleLinked:
            return ("Vehicle-linked", Color(red: 232 / 255, green: 245 / 255, blue: 233 / 255), Color(red: 27 / 255, green: 94 / 255, blue: 32 / 255))
        case .shiftBased:
            return ("Shift · ends \(card.shiftEnd)", Color(red: 254 / 255, green: 243 / 255, blue: 199 / 255), Color(red: 146 / 255, green: 64 / 255, blue: 14 / 255))
        case .tripLinked:
            return ("Trip · ends \(card.tripEnd)", Color(red: 219 / 255, green: 234 / 255, blue: 254 / 255), Color(red: 30 / 255, green: 64 / 255, blue: 175 / 255))
        }
    }

    private func profileRegisteredLine() -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        let dates: [Date] = apiAssignments.compactMap { a in
            guard let s = a.assignedAt?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
            return iso.date(from: s) ?? iso2.date(from: s)
        }
        guard let minD = dates.min() else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: minD)
    }

    private var fleetOperatorDisplay: String {
        let fp = fleetPinFoDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fp.isEmpty { return fp }
        if let n = apiHome?.foName?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
        return "—"
    }

    private var driverIdLine: String {
        guard let d = apiProfile?.driverId, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "—" }
        return d
    }

    private var profileSubtitle: String {
        if liveMode, let p = apiProfile {
            if let st = p.foStatus?.trimmingCharacters(in: .whitespacesAndNewlines), !st.isEmpty {
                return "Driver · \(st)"
            }
            if let n = apiHome?.foName?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
                return "Driver · \(n)"
            }
            return "Driver"
        }
        let fp = fleetPinFoDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fp.isEmpty { return "Driver · \(fp)" }
        return "Driver"
    }

    private var licenceLine: String {
        guard let d = apiProfile?.dlNumber?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty else {
            return "—"
        }
        return d
    }

    private var navHighlightIndex: Int? {
        if mainContent >= 0, mainContent <= 3 { return mainContent }
        return nil
    }

    var body: some View {
        Group {
            if onboardingStep != "complete" {
                onboarding
            } else {
                mainShell
            }
        }
        .task(id: "\(liveMode)-\(onboardingStep)-\(foScopedToken ?? "")") {
            await refreshDashboardIfNeeded()
        }
        .task(id: "\(liveMode)-\(onboardingStep)-\(foScopedToken ?? "")-\(activeCard)-\(bindingsEffective.map(\.id).joined(separator: ","))") {
            await loadTransactionsIfNeeded()
        }
        .onChange(of: otpDigits.joined()) { newVal in
            guard liveMode, onboardingStep == "login_otp", newVal.count == 6, onboardingAction == nil else { return }
            Task { await verifyLoginOtpLive() }
        }
        .onChange(of: mainContent) { tab in
            guard tab == 1 else { return }
            if selectedScan == nil, let first = scanEligible.first { selectedScan = first }
        }
        .onChange(of: onboardingStep) { step in
            if step == "fo_pin_login" {
                resetFoForgotLocals()
                foPinEntry = ""
            }
        }
        .onChange(of: profilePinModalOpen) { open in
            if open {
                resetProfilePinModalLocals()
            }
        }
        .onChange(of: apiBanner) { _, newVal in
            if newVal != nil { successBanner = nil }
        }
        .onChange(of: successBanner) { _, newVal in
            if newVal != nil { apiBanner = nil }
        }
        .task(id: apiBanner) {
            guard apiBanner != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            apiBanner = nil
        }
        .task(id: successBanner) {
            guard successBanner != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            successBanner = nil
        }
        .task(id: otpCountdown) {
            guard otpCountdown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                if otpCountdown > 0 { otpCountdown -= 1 }
            }
        }
        .task(id: scanSessionOtpCountdown) {
            guard scanSessionOtpCountdown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                if scanSessionOtpCountdown > 0 { scanSessionOtpCountdown -= 1 }
            }
        }
        .background(FleetNativeBackHandlerRegistration(onBack: handleNativeBack))
    }

    /// Android `BackHandler` parity (edge-swipe + Escape on iPad).
    private func handleNativeBack() -> Bool {
        if onboardingStep != "complete" {
            switch onboardingStep {
            case "login_otp":
                onboardingStep = "login"
                otpDigits = Array(repeating: "", count: 6)
                otpError = ""
                return true
            case "1c":
                if liveMode {
                    inviteOtpRef = nil
                    inviteMobileVerificationToken = nil
                    inviteField = ""
                    onboardingStep = "login"
                } else {
                    onboardingStep = "1b"
                }
                return true
            case "select_fo":
                onboardingStep = "login_otp"
                otpPhaseToken = nil
                return true
            case "fo_pin_login":
                if foPinSubStep == "forgot" {
                    foPinSubStep = "enter"
                    resetFoForgotLocals()
                    foPinEntry = ""
                    return true
                }
                foPinEntry = ""
                let fos = foOrganizationList.filter { $0.foStatus == "ACTIVE" }
                if fos.count > 1 {
                    onboardingStep = "select_fo"
                } else {
                    onboardingStep = "login_otp"
                    otpPhaseToken = nil
                }
                return true
            case "1b":
                onboardingStep =
                    liveMode && inviteMobileVerificationToken != nil ? "1d" : "login"
                return true
            case "1d":
                if liveMode {
                    inviteOtpRef = nil
                    inviteField = ""
                    onboardingStep = "1c"
                } else {
                    onboardingStep = "1c"
                }
                return true
            case "set_pin":
                onboardingStep = "login_otp"
                return true
            case "1e":
                onboardingStep = "1d"
                return true
            case "1f":
                onboardingStep = "1e"
                return true
            case "confirm_pin":
                onboardingStep = onboardingStep.hasPrefix("1") ? "1e" : "set_pin"
                return true
            case "registered":
                onboardingStep = "confirm_pin"
                return true
            case "forgot_pin":
                onboardingStep = "login"
                return true
            case "login":
                onFinish(.failure(FleetSdkError(code: .userCancelled, message: "User cancelled.")))
                return true
            default:
                return false
            }
        }

        if overlay == "accepted" {
            overlay = "none"
            return true
        }
        if overlay == "pairing" {
            pairingField = ""
            pairingError = ""
            pairingSuccess = false
            pairingAttempts = 0
            overlay = "assignment"
            return true
        }
        if overlay == "assignment" {
            overlay = "none"
            assignmentPick = nil
            return true
        }
        if sessionPhase != "idle" {
            switch sessionPhase {
            case "confirmation":
                resetScanSession()
                return true
            case "pin_confirm":
                sessionPhase = "confirmation"
                sessionPin = ""
                return true
            case "otp_entry":
                sessionPhase = "pin_confirm"
                sessionOtpDigits = Array(repeating: "", count: 6)
                scanSessionOtpCountdown = 0
                return true
            case "authorized":
                return true
            case "complete":
                sessionPhase = "idle"
                sessionIdle = true
                sessionPin = ""
                sessionOtpDigits = Array(repeating: "", count: 6)
                scanSessionOtpCountdown = 0
                mainContent = 0
                selectedScan = nil
                parsedScanQr = nil
                lastQrPay = nil
                return true
            default:
                return true
            }
        }
        if mainContent != 0 {
            mainContent = 0
            return true
        }
        onFinish(.failure(FleetSdkError(code: .userCancelled, message: "Back closed flow.")))
        return true
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
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let s = successBanner {
                    FleetApiFeedbackBanner(message: s, tone: .success, onDismiss: { successBanner = nil })
                        .padding(.horizontal, 12)
                }
                if let b = apiBanner {
                    FleetApiFeedbackBanner(message: b, tone: .error, onDismiss: { apiBanner = nil })
                        .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 52)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch onboardingStep {
        case "login":
            loginStep
        case "login_otp":
            LoginOtpParityView(
                mobileNumber: mobile,
                otpDigits: $otpDigits,
                otpError: otpError,
                otpCountdown: otpCountdown,
                refocusKey: loginOtpRefocusKey,
                isVerifying: onboardingAction == "login_verify_otp",
                isResending: onboardingAction == "login_resend_otp",
                onBack: {
                    onboardingStep = "login"
                    otpDigits = Array(repeating: "", count: 6)
                    otpError = ""
                },
                onResend: { resendLoginOtp() },
                onVerify: { verifyLoginOtpTapped() },
            )
        case "forgot_pin":
            forgotPinReactStep
        case "set_pin":
            SetPinParityView(
                isNewUser: !isRegistered,
                pin: rstPin,
                onDigit: { d in if rstPin.count < 6 { rstPin += d } },
                onBackspace: { rstPin = String(rstPin.dropLast()) },
                onNext: { if rstPin.count == 6 { onboardingStep = "confirm_pin" } },
            )
        case "confirm_pin":
            ConfirmPinParityView(
                pinConfirm: rstPinConfirm,
                pinError: rstPinError,
                onDigit: { d in
                    if rstPinConfirm.count < 6 { rstPinConfirm += d }
                    rstPinError = ""
                },
                onBackNavigation: {
                    rstPinConfirm = ""
                    rstPinError = ""
                    apiBanner = nil
                    onboardingStep = "set_pin"
                },
                onBackspace: { rstPinConfirm = String(rstPinConfirm.dropLast()) },
                onSubmit: { submitConfirmPin() },
            )
        case "registered":
            RegisteredParityView(onContinue: {
                rstPin = ""
                rstPinConfirm = ""
                isRegistered = true
                onboardingStep = "complete"
            })
        case "invite":
            inviteStep
        case "select_fo":
            selectFoStep
        case "fo_pin_login":
            foPinLoginStep
        case "1c":
            inviteMobileStepLive
        case "1d":
            inviteOtpLiveStep
        case "1b":
            inviteCodeLiveStep
        case "1e":
            InvitePinSetupParityView(
                pin: nuPinInvite,
                onDigit: { d in if nuPinInvite.count < 6 { nuPinInvite += d } },
                onBackspace: { nuPinInvite = String(nuPinInvite.dropLast()) },
                onNext: { if nuPinInvite.count == 6 { onboardingStep = "1f" } },
            )
        case "1f":
            InvitePinConfirmParityView(
                pinConfirm: nuPinInviteConfirm,
                pinError: pinInviteError,
                isSubmitting: onboardingAction == "invite_set_pin",
                onDigit: { d in
                    if nuPinInviteConfirm.count < 6 { nuPinInviteConfirm += d }
                    pinInviteError = ""
                },
                onBackNavigation: {
                    nuPinInviteConfirm = ""
                    pinInviteError = ""
                    onboardingStep = "1e"
                },
                onBackspace: { nuPinInviteConfirm = String(nuPinInviteConfirm.dropLast()) },
                onSubmit: { inviteSetPinConfirm() },
            )
        default:
            EmptyView()
        }
    }

    private var loginStep: some View {
        let showFormatError =
            !mobile.isEmpty && !(mobile.first.map { ch in "6789".contains(ch) } ?? true)
        return VStack(spacing: 24) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 82 / 255, green: 82 / 255, blue: 91 / 255).opacity(0.8), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 63 / 255, green: 63 / 255, blue: 70 / 255)))
                    Text("MGL")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .fixedSize()
                Text("Driver App")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 24) {
                Text("Sign in to continue")
                    .font(.headline)
                    .foregroundStyle(Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255))
                Text("Mobile number")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 113 / 255, green: 128 / 255, blue: 150 / 255))
                if showFormatError {
                    Text("Please enter a valid mobile number")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 254 / 255, green: 242 / 255, blue: 242 / 255)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 254 / 255, green: 202 / 255, blue: 202 / 255)))
                }
                HStack(spacing: 0) {
                    Text("+91")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .foregroundStyle(Color(red: 113 / 255, green: 128 / 255, blue: 150 / 255))
                    Rectangle()
                        .fill(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255))
                        .frame(width: 1)
                    TextField(
                        "98765 01234",
                        text: Binding(
                            get: { mobile },
                            set: { mobile = String($0.filter(\.isNumber).prefix(10)) },
                        ),
                    )
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))

                Button {
                    apiBanner = nil
                    otpDigits = Array(repeating: "", count: 6)
                    otpError = ""
                    onboardingAction = nil
                    if liveMode {
                        guard DriverFleetQr.validIndianMobile10(mobile) else { return }
                        Task { @MainActor in
                            onboardingAction = "login_send_mobile_check"
                            defer { onboardingAction = nil }
                            switch await api.driverCheckMobile(mobile) {
                            case let .failure(e):
                                apiBanner = ReactParityBanner.forGenericFailure(e)
                            case let .success(status):
                                switch status {
                                case .newUser:
                                    apiBanner = ReactParityBanner.newUserContinueInvite
                                    inviteOtpRef = nil
                                    inviteMobileVerificationToken = nil
                                    inviteField = ""
                                    onboardingStep = "1c"
                                case .returningUser:
                                    _ = await api.driverSendLoginOtp(mobile)
                                    otpCountdown = 60
                                    onboardingStep = "login_otp"
                                }
                            }
                        }
                    } else {
                        otpCountdown = 30
                        onboardingStep = "login_otp"
                    }
                } label: {
                    if onboardingAction == "login_send_mobile_check" {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Send OTP")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255))
                .disabled(!DriverFleetQr.validIndianMobile10(mobile) || onboardingAction == "login_send_mobile_check")

                Rectangle()
                    .fill(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255))
                    .frame(height: 1)

                Button {
                    inviteField = ""
                    apiBanner = nil
                    inviteOtpRef = nil
                    inviteMobileVerificationToken = nil
                    if liveMode {
                        mobile = ""
                        onboardingStep = "1c"
                    } else {
                        onboardingStep = "1b"
                    }
                } label: {
                    Text("New user? I have an invite code")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)),
            )

            Text("By continuing, I agree to MGL Fleet Terms of Service")
                .font(.caption)
                .foregroundStyle(Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 448)
    }

    private var forgotPinReactStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                onboardingStep = "login"
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
            }
            .buttonStyle(.plain)
            Text("Reset PIN")
                .font(.title3)
                .bold()
                .foregroundStyle(Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255))
            Text("Sign out and open Login with your mobile OTP, or contact your fleet operator for help.")
                .font(.subheadline)
                .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
            Button("Back to login") {
                onboardingStep = "login"
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255))
        }
    }

    private var inviteStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnboardingBackRow { onboardingStep = "login" }
            Text("Invite code").font(.title3).bold()
            TextField(
                "ABC123",
                text: Binding(
                    get: { inviteField },
                    set: { inviteField = String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(24)) },
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

    private var selectFoStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnboardingBackRow {
                otpPhaseToken = nil
                onboardingStep = "login_otp"
            }
            Text("Choose fleet operator").font(.title3).bold()
            ForEach(Array(foOrganizationList.filter { $0.foStatus == "ACTIVE" }.enumerated()), id: \.offset) { _, fo in
                Button {
                    selectedFoCompanyId = fo.foCompanyId
                    fleetPinFoDisplay = fo.foName
                    foPinEntry = ""
                    onboardingStep = "fo_pin_login"
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fo.foName).font(.headline)
                        Text("Fleet ID #\(fo.foCompanyId)").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleForgotFleetPinPrimaryTap() {
        apiBanner = nil
        forgotFleetPinError = ""
        if forgotFleetPinPhase == "first" {
            guard forgotFleetPinFirst.count == 6 else { return }
            forgotFleetPinPhase = "second"
            forgotFleetPinSecond = ""
        } else {
            guard forgotFleetPinSecond.count == 6 else { return }
            guard forgotFleetPinSecond == forgotFleetPinFirst else {
                forgotFleetPinError = ReactParityBanner.pinsDidntMatchConfirm
                forgotFleetPinSecond = ""
                return
            }
            guard let sel = selectedFoCompanyId, let phase = otpPhaseToken else { return }
            Task {
                onboardingAction = "forgot_pin_reset"
                defer { onboardingAction = nil }
                let r = await api.driverPinReset(bearerPartial: phase, foCompanyId: sel, newPin: forgotFleetPinSecond)
                switch r {
                case let .failure(e):
                    apiBanner = ReactParityBanner.forPinFailure(e)
                    forgotFleetPinSecond = ""
                case .success:
                    otpPhaseToken = nil
                    foScopedToken = nil
                    foOrganizationList = []
                    selectedFoCompanyId = nil
                    persistedFoCompanyId = nil
                    fleetPinFoDisplay = ""
                    foPinEntry = ""
                    foPinSubStep = "enter"
                    resetFoForgotLocals()
                    onboardingStep = "login"
                    successBanner =
                        "PIN changed successfully. Tap Send OTP and sign in with your new PIN."
                }
            }
        }
    }

    private func handleProfileChangePinPrimaryTap() {
        apiBanner = nil
        profileChangePinError = ""
        if profileChangePinPhase == "first" {
            guard profileChangePinFirst.count == 6 else { return }
            profileChangePinPhase = "second"
            profileChangePinSecond = ""
        } else {
            guard profileChangePinSecond.count == 6 else { return }
            guard profileChangePinSecond == profileChangePinFirst else {
                profileChangePinError = ReactParityBanner.pinsDidntMatchConfirm
                profileChangePinSecond = ""
                return
            }
            guard let tok = foScopedToken, let foCo = effectiveFoCompanyIdForPin else { return }
            Task {
                profilePinChanging = true
                defer { profilePinChanging = false }
                let r =
                    await api.driverPinReset(
                        bearerPartial: tok,
                        foCompanyId: foCo,
                        newPin: profileChangePinSecond,
                    )
                switch r {
                case let .failure(e):
                    apiBanner = ReactParityBanner.forPinFailure(e)
                    profileChangePinSecond = ""
                case .success:
                    profilePinModalOpen = false
                    resetProfilePinModalLocals()
                    successBanner = "PIN changed successfully."
                }
            }
        }
    }

    private var foPinLoginStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    apiBanner = nil
                    successBanner = nil
                    if foPinSubStep == "forgot" {
                        foPinSubStep = "enter"
                        resetFoForgotLocals()
                        foPinEntry = ""
                        return
                    }
                    foPinEntry = ""
                    let fos = foOrganizationList.filter { $0.foStatus == "ACTIVE" }
                    if fos.count > 1 {
                        onboardingStep = "select_fo"
                    } else {
                        otpPhaseToken = nil
                        onboardingStep = "login_otp"
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back").font(.caption)
                    }
                    .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if foPinSubStep == "enter" {
                Text("Enter Fleet PIN").font(.title3).bold()
                Text("Enter your 6-digit PIN for this fleet.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(fleetPinFoDisplay.isEmpty ? "—" : fleetPinFoDisplay).font(.headline)
                PinDotsView(value: foPinEntry)
                NumpadView(
                    enabled: onboardingAction != "fo_unlock",
                    onDigit: { d in if onboardingAction != "fo_unlock", foPinEntry.count < 6 { foPinEntry += d } },
                    onBackspace: { foPinEntry = String(foPinEntry.dropLast()) },
                )
                Button(onboardingAction == "fo_unlock" ? "Unlocking…" : "Unlock app") {
                    guard let sel = selectedFoCompanyId, let phase = otpPhaseToken, foPinEntry.count == 6 else { return }
                    Task {
                        onboardingAction = "fo_unlock"
                        defer { onboardingAction = nil }
                        let tok = await api.driverFoSelect(bearerPartial: phase, foCompanyId: sel, pin: foPinEntry)
                        switch tok {
                        case let .failure(e):
                            apiBanner = ReactParityBanner.forPinFailure(e)
                            foPinEntry = ""
                        case let .success(fleetTok):
                            foScopedToken = fleetTok
                            persistedFoCompanyId = sel
                            otpPhaseToken = nil
                            foPinEntry = ""
                            apiBanner = nil
                            onboardingStep = "complete"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
                .disabled(foPinEntry.count != 6 || selectedFoCompanyId == nil || onboardingAction == "fo_unlock")

                Button("Forgot PIN?") {
                    apiBanner = nil
                    successBanner = nil
                    forgotFleetPinError = ""
                    forgotFleetPinPhase = "first"
                    forgotFleetPinFirst = ""
                    forgotFleetPinSecond = ""
                    foPinSubStep = "forgot"
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                .disabled(!liveMode || selectedFoCompanyId == nil || otpPhaseToken == nil)
            } else {
                Text(forgotFleetPinPhase == "first" ? "Enter New PIN" : "Confirm New PIN")
                    .font(.title3).bold()
                Text(
                    forgotFleetPinPhase == "first"
                        ? "Choose a new 6-digit fleet PIN."
                        : "Re-enter your new PIN. After reset you will verify OTP again with this PIN.",
                )
                .font(.caption).foregroundStyle(.secondary)
                let forgotPin = forgotFleetPinPhase == "first" ? forgotFleetPinFirst : forgotFleetPinSecond
                PinDotsView(value: forgotPin)
                let resetBusy = onboardingAction == "forgot_pin_reset"
                NumpadView(
                    enabled: !resetBusy,
                    onDigit: { digit in
                        if resetBusy { return }
                        if forgotFleetPinPhase == "first" {
                            if forgotFleetPinFirst.count < 6 { forgotFleetPinFirst += digit }
                        } else if forgotFleetPinSecond.count < 6 {
                            forgotFleetPinSecond += digit
                        }
                        forgotFleetPinError = ""
                    },
                    onBackspace: {
                        if forgotFleetPinPhase == "first" {
                            forgotFleetPinFirst = String(forgotFleetPinFirst.dropLast())
                        } else {
                            forgotFleetPinSecond = String(forgotFleetPinSecond.dropLast())
                        }
                    },
                )
                if !forgotFleetPinError.isEmpty {
                    Text(forgotFleetPinError).font(.caption).foregroundStyle(.red)
                }
                let btnLabel =
                    resetBusy ? "Resetting…"
                        : (forgotFleetPinPhase == "first" ? "Confirm PIN" : "Reset PIN")
                let canForgot =
                    !resetBusy && liveMode && selectedFoCompanyId != nil && otpPhaseToken != nil &&
                    (forgotFleetPinPhase == "first" ? forgotFleetPinFirst.count == 6 : forgotFleetPinSecond.count == 6)
                if forgotFleetPinPhase == "first" {
                    Button(btnLabel, action: handleForgotFleetPinPrimaryTap)
                        .buttonStyle(.bordered)
                        .tint(FleetParityColors.green700)
                        .disabled(!canForgot)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                } else {
                    Button(btnLabel, action: handleForgotFleetPinPrimaryTap)
                        .buttonStyle(.borderedProminent)
                        .tint(FleetParityColors.green700)
                        .disabled(!canForgot)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }
            }
        }
    }

    private var inviteMobileStepLive: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnboardingBackRow { onboardingStep = liveMode ? "login" : "1b" }
            Text("Verify mobile").font(.title3).bold()
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
                apiBanner = nil
                guard liveMode else {
                    inviteOtpDigits = Array(repeating: "", count: 6)
                    focusedOtpDigitIndex = 0
                    otpCountdown = 30
                    onboardingStep = "1d"
                    return
                }
                guard DriverFleetQr.validIndianMobile10(mobile) else {
                    apiBanner = ReactParityBanner.validMobileError
                    return
                }
                Task {
                    onboardingAction = "invite_send"
                    defer { onboardingAction = nil }
                    switch await api.driverCheckMobile(mobile) {
                    case let .failure(e):
                        apiBanner = ReactParityBanner.forGenericFailure(e)
                    case let .success(st):
                        if st == .returningUser {
                        apiBanner = ReactParityBanner.useSendOtpOnLogin
                            return
                        }
                        switch await api.driverInviteMobileSendOtp(mobile) {
                        case let .failure(e): apiBanner = ReactParityBanner.forGenericFailure(e)
                        case let .success(ref):
                            inviteOtpRef = ref
                            inviteOtpDigits = Array(repeating: "", count: 6)
                            focusedOtpDigitIndex = 0
                            otpCountdown = 60
                            onboardingStep = "1d"
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
            .disabled(mobile.count != 10 || onboardingAction == "invite_send")
        }
    }

    private var inviteOtpLiveStep: some View {
        LoginOtpParityView(
            mobileNumber: mobile,
            otpDigits: $inviteOtpDigits,
            otpError: "",
            otpCountdown: otpCountdown,
            refocusKey: inviteOtpRefocusKey,
            isVerifying: onboardingAction == "invite_verify_otp",
            isResending: onboardingAction == "invite_resend_otp",
            onBack: { onboardingStep = "1c" },
            onResend: { resendInviteOtp() },
            onVerify: { inviteVerifyOtpTapped() },
        )
    }

    private var inviteCodeLiveStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnboardingBackRow {
                onboardingStep = liveMode && inviteMobileVerificationToken != nil ? "1d" : "login"
            }
            Text("Invite code").font(.title3).bold()
            TextField(
                "ABC123",
                text: Binding(
                    get: { inviteField },
                    set: { inviteField = String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(24)) },
                ),
            )
            .textFieldStyle(.roundedBorder)
            if !liveMode, FleetReactMockIOS.inviteCodes[inviteField] != nil {
                Text(FleetReactMockIOS.inviteCodes[inviteField] ?? "").font(.caption).padding(8).background(Color.green.opacity(0.15))
            }
            Button("Continue") {
                if liveMode {
                    guard let tok = inviteMobileVerificationToken, inviteField.count >= 6 else {
                        apiBanner = ReactParityBanner.inviteVerifyMobileFirst
                        return
                    }
                    Task {
                        onboardingAction = "invite_validate"
                        defer { onboardingAction = nil }
                        let r = await api.driverInviteValidate(mobile: mobile, inviteCode: inviteField, mobileVerificationToken: tok)
                        switch r {
                        case let .failure(e): apiBanner = ReactParityBanner.forGenericFailure(e)
                        case let .success(v):
                            validatedInvite = v
                            inviteSessionToken = v.sessionToken
                            fleetPinFoDisplay = v.foName
                            nuPinInvite = ""
                            nuPinInviteConfirm = ""
                            pinInviteError = ""
                            onboardingStep = "1e"
                        }
                    }
                } else if FleetReactMockIOS.inviteCodes[inviteField] != nil {
                    onboardingStep = "1c"
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                inviteField.count < 6
                    || (!liveMode && FleetReactMockIOS.inviteCodes[inviteField] == nil)
                    || (liveMode && (inviteMobileVerificationToken?.isEmpty ?? true)),
            )
        }
    }

    private var profileChangePinOverlay: some View {
        Group {
            if profilePinModalOpen {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    ScrollView {
                        ProfileChangePinParityView(
                            phase: profileChangePinPhase,
                            pinFirst: profileChangePinFirst,
                            pinSecond: profileChangePinSecond,
                            pinError: profileChangePinError,
                            isChanging: profilePinChanging,
                            onBack: {
                                guard !profilePinChanging else { return }
                                profilePinModalOpen = false
                            },
                            onDigit: { digit in
                                if profilePinChanging { return }
                                if profileChangePinPhase == "first" {
                                    if profileChangePinFirst.count < 6 { profileChangePinFirst += digit }
                                } else if profileChangePinSecond.count < 6 {
                                    profileChangePinSecond += digit
                                }
                                profileChangePinError = ""
                            },
                            onBackspace: {
                                if profileChangePinPhase == "first" {
                                    profileChangePinFirst = String(profileChangePinFirst.dropLast())
                                } else {
                                    profileChangePinSecond = String(profileChangePinSecond.dropLast())
                                }
                            },
                            onPrimary: handleProfileChangePinPrimaryTap,
                        )
                    }
                }
                .zIndex(250)
            }
        }
    }

    private var mainShell: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                Group {
                    switch mainContent {
                    case 0: cardTab
                    case 1: scanTab
                    case 2: assignmentsSectioned
                    case 3: profileTab
                    case 4: transactionsTabIos
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    (mainContent == 0 || mainContent == 2)
                        ? Color(red: 236 / 255, green: 239 / 255, blue: 241 / 255)
                        : Color(.systemBackground),
                )
                Divider()
                HStack(spacing: 0) {
                    iosTabItem(0, "house.fill", "Home")
                    iosTabItem(1, "qrcode", "Scan & Pay")
                    iosTabItem(2, "shippingbox", "My Vehicles")
                    iosTabItem(3, "person.fill", "Profile")
                }
                .padding(.vertical, 8)
            }

            overlayContent

            profileChangePinOverlay

            VStack {
                Spacer()
                VStack(spacing: 8) {
                    if let s = successBanner {
                        FleetApiFeedbackBanner(message: s, tone: .success, onDismiss: { successBanner = nil })
                    }
                    if let b = apiBanner {
                        FleetApiFeedbackBanner(message: b, tone: .error, onDismiss: { apiBanner = nil })
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 96)
            }
            .allowsHitTesting(successBanner != nil || apiBanner != nil)
            .zIndex(300)
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
        .alert("Decline this assignment?", isPresented: $showDeclineConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, decline", role: .destructive) {
                overlay = "none"
                assignmentPick = nil
                successBanner = "Assignment declined"
            }
        } message: {
            Text("Your Fleet Operator will be notified.")
        }
        .sheet(item: $detailBinding) { b in
            assignmentDetailSheet(b)
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
                openPairingFor(pairingAssignment)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255))
            Button("Decline") {
                showDeclineConfirm = true
            }
            .foregroundStyle(.red)
            Button("Close") {
                overlay = "none"
                assignmentPick = nil
            }
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
                    if liveMode {
                        guard let tok = foScopedToken else {
                            pairingError = "Session expired. Sign in again."
                            return
                        }
                        Task {
                            let r = await api.driverAcceptPairing(tok, pairingCode: pairingField)
                            switch r {
                            case let .failure(e):
                                await MainActor.run {
                                    pairingAttempts += 1
                                    pairingError = e.localizedDescription
                                    pairingField = ""
                                }
                            case .success:
                                let nh = await api.driverGetHome(tok)
                                let na = await api.driverGetAssignments(tok)
                                await MainActor.run {
                                    pairingSuccess = true
                                    pairingError = ""
                                    if case let .success(h) = nh { apiHome = h }
                                    if case let .success(a) = na { apiAssignments = a }
                                }
                                try? await Task.sleep(nanoseconds: 900_000_000)
                                await MainActor.run {
                                    pairingSuccess = false
                                    pairingField = ""
                                    pairingAttempts = 0
                                    overlay = "accepted"
                                }
                            }
                        }
                    } else if pairingField == pairingAssignment.validPairingCode ?? "" {
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
                assignmentPick = nil
                mainContent = 2
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
        let headerGreen = Color(red: 26 / 255, green: 48 / 255, blue: 32 / 255)
        let muted = Color(red: 200 / 255, green: 230 / 255, blue: 201 / 255)
        let avatarRing = Color(red: 45 / 255, green: 74 / 255, blue: 54 / 255)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(indiaGreeting()).font(.subheadline).foregroundStyle(muted)
                Text(displayDriver.name).font(.title3).bold().foregroundStyle(.white)
            }
            Spacer()
            Text(displayDriver.initials)
                .bold()
                .font(.subheadline)
                .frame(width: 40, height: 40)
                .background(avatarRing)
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 2))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(headerGreen)
    }

    private var transactionsTabIos: some View {
        let rows = txnSource.filter { t in
            switch txnFilterIos {
            case "successful": return txnStatusSuccess(t.status)
            case "failed": return !txnStatusSuccess(t.status)
            default: return true
            }
        }
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Transactions").font(.title2.bold())
                HStack(spacing: 8) {
                    ForEach([("all", "All"), ("successful", "Successful"), ("failed", "Failed")], id: \.0) { pair in
                        let f = pair.0
                        let label = pair.1
                        Button {
                            txnFilterIos = f
                        } label: {
                            Text(label)
                                .font(.caption).padding(.horizontal, 14).padding(.vertical, 8)
                                .background(txnFilterIos == f ? Color.green : Color(.secondarySystemBackground))
                                .foregroundStyle(txnFilterIos == f ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if rows.isEmpty {
                    Text(
                        txnFilterIos == "successful"
                            ? "No successful transactions"
                            : txnFilterIos == "failed" ? "No failed transactions" : "No transactions",
                    )
                    .foregroundStyle(.secondary)
                    .padding()
                } else {
                    ForEach(rows) { t in
                        let credit =
                            t.type.lowercased() == "credit"
                            || t.status.range(of: "credit|top-up|wallet|neft", options: [.regularExpression, .caseInsensitive]) != nil
                        HStack {
                            VStack(alignment: .leading) {
                                Text(t.station).bold()
                                Text(t.vrn).font(.caption).foregroundStyle(.secondary)
                                Text(t.date).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(credit ? "+" : "-")₹\(t.amount)")
                                .bold()
                                .foregroundStyle(credit ? Color.green : Color.primary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }

    private func txnIsCreditRow(_ t: DemoTxn) -> Bool {
        if t.type.lowercased() == "credit" { return true }
        return t.status.range(of: "credit|top-up|top up|wallet|neft", options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func recentTxnSubtitle(_ t: DemoTxn) -> (String, String) {
        let raw = t.date
        let segs = raw.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false)
        if segs.count == 2 {
            return (String(segs[0]), String(segs[1].prefix(5)))
        }
        return (raw, "")
    }

    private var cardTab: some View {
        let cards = activeCards
        let idx = min(activeCard, max(cards.count - 1, 0))
        let c = cards[safe: idx]
        let noV = cards.isEmpty
        let noTx = txnSource.isEmpty
        let recent3 = Array(txnSource.prefix(3))
        let scanGreen = Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if pendingAssignmentCount > 0 {
                    HStack(alignment: .center) {
                        Text("\(pendingAssignmentCount) assignment\(pendingAssignmentCount > 1 ? "s" : "") need your attention")
                            .font(.subheadline)
                            .foregroundStyle(Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255))
                        Spacer()
                        Button("View") {
                            mainContent = 2
                            if let first = bindingsEffective.first(where: {
                                $0.state == .pendingAcceptance || (!$0.paired && $0.state == .active)
                            }) {
                                openAssignmentNotification(first)
                            }
                        }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                    }
                    .padding(12)
                    .background(Color(red: 255 / 255, green: 251 / 255, blue: 235 / 255))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 253 / 255, green: 230 / 255, blue: 138 / 255)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if noV && noTx {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(red: 125 / 255, green: 145 / 255, blue: 136 / 255))
                            .frame(width: 72, height: 72)
                            .background(Color(red: 241 / 255, green: 244 / 255, blue: 242 / 255))
                            .clipShape(Circle())
                        Text("No vehicles or transactions").font(.headline)
                        Text("There's nothing to show yet. When your fleet operator assigns you a vehicle and you use Scan & Pay, your balance and activity will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if pendingAssignmentCount > 0 {
                            Button("Go to vehicles") { mainContent = 2 }
                                .buttonStyle(.borderedProminent)
                                .tint(scanGreen)
                        } else {
                            Button("Browse vehicles") { mainContent = 2 }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                } else if noV {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(Color(red: 125 / 255, green: 145 / 255, blue: 136 / 255))
                            .frame(width: 56, height: 56)
                            .background(Color(red: 241 / 255, green: 244 / 255, blue: 242 / 255))
                            .clipShape(Circle())
                        Text("No active vehicle").font(.headline)
                        Text("You don't have a paired vehicle right now. Accept an assignment to unlock Scan & Pay.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if pendingAssignmentCount > 0 {
                            Button("View vehicles") { mainContent = 2 }
                                .buttonStyle(.borderedProminent)
                                .tint(scanGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                    recentSection(recent3, showViewAll: !txnSource.isEmpty, scanGreen: scanGreen)
                } else if let card = c {
                    ZStack {
                        if activeCard > 0 {
                            HStack {
                                Button {
                                    activeCard -= 1
                                } label: {
                                    Image(systemName: "chevron.left").foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        if activeCard < cards.count - 1 {
                            HStack {
                                Spacer()
                                Button {
                                    activeCard += 1
                                } label: {
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            let badge = authBadge(card.authMode, card: card)
                            HStack(alignment: .top) {
                                Text(foLine(for: card))
                                    .font(.subheadline)
                                    .foregroundStyle(Color(red: 75 / 255, green: 85 / 255, blue: 99 / 255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(badge.0)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(badge.2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(badge.1)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            Text(card.vrn)
                                .font(.title2.bold())
                                .monospaced()
                                .padding(.top, 16)
                                .foregroundStyle(Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255))
                            Divider().padding(.vertical, 16)
                            Text("VEHICLE BALANCE")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(2.2)
                                .foregroundStyle(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                            Text("₹\(card.balance)")
                                .font(.system(size: 28, weight: .bold))
                                .padding(.top, 8)
                                .foregroundStyle(Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255))
                            if card.incentiveBalance > 0 {
                                Text("Card ₹\(card.cardBalance) · Incentive ₹\(card.incentiveBalance)")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                                    .padding(.top, 8)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                        .padding(.horizontal, 8)
                    }
                    HStack(spacing: 8) {
                        ForEach(Array(cards.enumerated()), id: \.offset) { i, _ in
                            Capsule()
                                .fill(i == idx ? scanGreen : Color.gray.opacity(0.35))
                                .frame(width: i == idx ? 28 : 8, height: 8)
                                .onTapGesture { activeCard = i }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    let scanBlocked = card.scanPayStatus == "out_window"
                    Button {
                        mainContent = 1
                    } label: {
                        Label("Scan & Pay", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(scanGreen)
                    .disabled(scanBlocked)
                    recentSection(recent3, showViewAll: !noTx, scanGreen: scanGreen)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func recentSection(_ rows: [DemoTxn], showViewAll: Bool, scanGreen: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent").font(.headline)
                Spacer()
                if showViewAll && !rows.isEmpty {
                    Button("View all") { mainContent = 4 }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                }
            }
            .padding(.top, 8)
            if rows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No transactions yet").font(.subheadline.weight(.medium))
                    Text("Fuel payments and wallet activity will show here once you use Scan & Pay.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(rows) { t in
                    let credit = txnIsCreditRow(t)
                    let parts = recentTxnSubtitle(t)
                    HStack(spacing: 12) {
                        Text(credit ? "↑" : "↓")
                            .font(.headline)
                            .foregroundStyle(credit ? Color.green : Color.red)
                            .frame(width: 40, height: 40)
                            .background(credit ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.station).font(.subheadline.weight(.semibold))
                            Text("\(t.vrn) · \(parts.0)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(credit ? "+" : "-")₹\(t.amount)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(credit ? Color.green : Color.primary)
                            if !parts.1.isEmpty {
                                Text(parts.1).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255)))
                }
            }
        }
    }

    private var scanTab: some View {
        let avail = scanEligible
        let sel = selectedScan ?? avail.first
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch sessionPhase {
                case "idle":
                    if avail.isEmpty {
                        let locked =
                            bindingsEffective.filter {
                                ["locked_unpaired", "locked_repair", "out_window"].contains($0.scanPayStatus)
                            }
                        VStack(spacing: 24) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(red: 209 / 255, green: 213 / 255, blue: 219 / 255))
                            Text("Scan & Pay unavailable")
                                .font(.headline)
                                .foregroundStyle(FleetParityColors.textPrimary)
                            Text("No vehicles available for scanning right now")
                                .font(.subheadline)
                                .foregroundStyle(FleetParityColors.gray500)
                                .multilineTextAlignment(.center)
                            if !locked.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(locked, id: \.id) { b in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(b.vrn).font(.subheadline.weight(.medium))
                                            Text(
                                                b.scanPayStatus == "locked_unpaired"
                                                    ? "Pair to unlock"
                                                    : b.scanPayStatus == "locked_repair"
                                                        ? "Re-pair required"
                                                        : b.scanPayStatus == "out_window"
                                                            ? "Outside shift/trip window"
                                                            : b.scanPayStatus.replacingOccurrences(of: "_", with: " "),
                                            )
                                            .font(.caption)
                                            .foregroundStyle(FleetParityColors.gray500)
                                        }
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            Button("Go to My Vehicles") { mainContent = 2 }
                                .buttonStyle(.borderedProminent)
                                .tint(FleetParityColors.green700)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else if let sel {
                        if avail.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(avail, id: \.id) { b in
                                        let picked = (selectedScan ?? avail.first)?.id == b.id
                                        Button(b.vrn) { selectedScan = b }
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(picked ? FleetParityColors.green600 : Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                                            .foregroundStyle(picked ? .white : FleetParityColors.green700)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fueling: \(sel.vrn)")
                                .font(.subheadline.weight(.medium))
                            HStack {
                                Text("Available balance")
                                    .font(.subheadline)
                                    .foregroundStyle(FleetParityColors.gray500)
                                Spacer()
                                Text("₹\(sel.balance)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255))
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        FleetInlineQrScanner(
                            active: sessionPhase == "idle",
                            scanResetKey: "\(sel.id)|\(sessionPhase)",
                            onBarcodeRaw: handleFleetpayQrScanned,
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 4))
                        Text("Point camera at the QR on the POS screen")
                            .font(.caption)
                            .foregroundStyle(FleetParityColors.gray500)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        if !liveMode {
                            Button("Simulate Scan") {
                                handleFleetpayQrScanned(DriverFleetQr.simulatedUri)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("Preparing Scan & Pay…").foregroundStyle(.secondary)
                    }

                case "confirmation":
                    HStack {
                        Text("Confirm fueling").font(.headline)
                        Spacer()
                        Button { resetScanSession() } label: {
                            Image(systemName: "xmark").foregroundStyle(FleetParityColors.gray500)
                        }
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255))
                        VStack(alignment: .leading, spacing: 4) {
                            Text({
                                let name = (parsedScanQr?.merchantName ?? "")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                return name.isEmpty
                                    ? (liveMode ? "—" : "MGL Hind CNG Filling Station")
                                    : name
                            }())
                            .font(.subheadline.weight(.semibold))
                            Group {
                                if let pq = parsedScanQr, !pq.mid.isEmpty {
                                    Text("MID \(pq.mid)")
                                } else {
                                    Text(liveMode ? "—" : "Andheri, Mumbai")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(FleetParityColors.gray500)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FleetParityColors.cardBorder))
                    if let b = sel {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Amount").font(.subheadline).foregroundStyle(FleetParityColors.gray500)
                                Spacer()
                                Text(
                                    parsedScanQr.map { "₹\(DriverFleetQr.paiseToInrDisplay($0.amountPaise))" } ?? "—",
                                )
                                .font(.subheadline.weight(.medium))
                            }
                            Divider()
                            HStack {
                                Text("Vehicle").font(.subheadline).foregroundStyle(FleetParityColors.gray500)
                                Spacer()
                                Text(b.vrn).font(.subheadline.weight(.medium))
                            }
                            HStack {
                                Text("Fleet Operator").font(.subheadline).foregroundStyle(FleetParityColors.gray500)
                                Spacer()
                                Text(b.fo).font(.subheadline.weight(.medium)).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("Available balance").font(.subheadline).foregroundStyle(FleetParityColors.gray500)
                                Spacer()
                                Text("₹\(b.balance)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255))
                            }
                        }
                        .padding(16)
                        .background(Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button("Continue") {
                        sessionPhase = "pin_confirm"
                        sessionPin = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FleetParityColors.green700)
                    .disabled(liveMode && parsedScanQr == nil)

                case "pin_confirm":
                    HStack(spacing: 12) {
                        Button {
                            sessionPhase = "confirmation"
                            sessionPin = ""
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(FleetParityColors.textPrimary)
                        }
                        Text("Enter PIN").font(.headline)
                        Spacer()
                    }
                    Text("Enter your PIN to confirm")
                        .font(.subheadline)
                        .foregroundStyle(FleetParityColors.textMuted)
                    PinDotsView(value: sessionPin)
                    NumpadView(
                        enabled: !qrPayBusy,
                        onDigit: { d in
                            if sessionPin.count < 6 { sessionPin += d; apiBanner = nil }
                        },
                        onBackspace: { sessionPin = String(sessionPin.dropLast()) },
                    )
                    Button(qrPayBusy ? "Processing…" : "Verify PIN", action: verifyScanSessionPinTapped)
                        .buttonStyle(.borderedProminent)
                        .tint(FleetParityColors.green700)
                        .disabled(sessionPin.count != 6 || qrPayBusy)

                case "otp_entry":
                    HStack(spacing: 12) {
                        Button { sessionPhase = "pin_confirm" } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(FleetParityColors.textPrimary)
                        }
                        Text("One-time password").font(.headline)
                        Spacer()
                    }
                    Text(otpScanBannerLine(mobile, maskedFromProfile: apiProfile?.maskedMobile))
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 239 / 255, green: 246 / 255, blue: 255 / 255))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 191 / 255, green: 219 / 255, blue: 254 / 255)))
                    if let b = sel {
                        let merchantName = (parsedScanQr?.merchantName ?? "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let merchant = merchantName.isEmpty ? (liveMode ? "—" : "Station") : merchantName
                        let amt =
                            parsedScanQr.map { DriverFleetQr.paiseToInrDisplay($0.amountPaise) }
                                ?? (liveMode ? "—" : "1,200.00")
                        Text("\(b.vrn) · \(merchant) · ₹\(amt)")
                            .font(.caption)
                            .foregroundStyle(Color(red: 75 / 255, green: 85 / 255, blue: 99 / 255))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    SixDigitOtpFieldsView(digits: $sessionOtpDigits)
                    if !liveMode {
                        Text("Session expires in 1:24")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    }
                    Button("Verify & Authorize") {
                        if sessionOtpDigits.joined().count == 6 {
                            sessionPhase = "authorized"
                            scanSessionOtpCountdown = 0
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FleetParityColors.green700)
                    .disabled(sessionOtpDigits.joined().count != 6)
                    if scanSessionOtpCountdown > 0 {
                        Text("Resend OTP in \(scanSessionOtpCountdown)s")
                            .font(.caption)
                            .foregroundStyle(FleetParityColors.textMuted)
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Resend OTP") {
                            if scanSessionOtpCountdown == 0 { scanSessionOtpCountdown = 60 }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FleetParityColors.green700)
                        .frame(maxWidth: .infinity)
                    }

                case "authorized":
                    ScanAuthorizedParityView(
                        parsedQr: parsedScanQr,
                        liveMode: liveMode,
                        lastPay: lastQrPay,
                        onFuelingComplete: { sessionPhase = "complete" },
                    )

                case "complete":
                    if let b = sel {
                        ScanCompleteReceiptParityView(
                            activeBinding: b,
                            parsedQr: parsedScanQr,
                            lastPay: lastQrPay,
                            liveMode: liveMode,
                            receiptDriverName: liveMode ? displayDriver.name : nil,
                            onSessionDone: { resetScanAfterComplete() },
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("—").foregroundStyle(FleetParityColors.textMuted)
                            Button("Done", action: resetScanAfterComplete)
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255))
                        }
                    }

                default:
                    EmptyView()
                }
            }
            .padding(16)
        }
    }

    private func resetScanSession() {
        sessionPhase = "idle"
        sessionIdle = true
        sessionPin = ""
        sessionOtpDigits = Array(repeating: "", count: 6)
        parsedScanQr = nil
        lastQrPay = nil
        apiBanner = nil
        scanSessionOtpCountdown = 0
    }

    private func resetScanAfterComplete() {
        resetScanSession()
        selectedScan = nil
        mainContent = 0
    }

    private func inviteVerifyOtpTapped() {
        let otp = inviteOtpDigits.joined()
        guard otp.count == 6 else { return }
        if liveMode {
            guard let ref = inviteOtpRef else {
                apiBanner = "Missing OTP reference."
                return
            }
            Task {
                await MainActor.run { onboardingAction = "invite_verify_otp" }
                let r = await api.driverInviteMobileVerifyOtp(mobile: mobile, otpRefNumber: ref, otp: otp)
                await MainActor.run {
                    onboardingAction = nil
                    switch r {
                    case let .failure(e):
                        apiBanner = ReactParityBanner.forOtpFailure(e)
                        inviteOtpDigits = Array(repeating: "", count: 6)
                        focusedOtpDigitIndex = 0
                    case let .success(t):
                        inviteMobileVerificationToken = t
                        inviteOtpDigits = Array(repeating: "", count: 6)
                        inviteField = ""
                        apiBanner = nil
                        onboardingStep = "1b"
                    }
                }
            }
        } else {
            inviteOtpDigits = Array(repeating: "", count: 6)
            onboardingStep = "1b"
            nuPinInvite = ""
        }
    }

    private func inviteSetPinConfirm() {
        if nuPinInviteConfirm != nuPinInvite {
            pinInviteError = "PINs don't match. Try again."
            nuPinInviteConfirm = ""
            return
        }
        pinInviteError = ""
        if !liveMode {
            onboardingStep = "complete"
            return
        }
        guard let sess = inviteSessionToken, !sess.isEmpty else {
            apiBanner = ReactParityBanner.sessionMissingInvite
            return
        }
        Task {
            await MainActor.run { onboardingAction = "invite_set_pin" }
            let r = await api.driverInviteSetPin(sessionToken: sess, pin: nuPinInvite)
            await MainActor.run {
                onboardingAction = nil
                switch r {
                case let .failure(e):
                    apiBanner = ReactParityBanner.forPinFailure(e)
                    nuPinInviteConfirm = ""
                case let .success(tok):
                    foScopedToken = tok
                    if let p = validatedInvite { fleetPinFoDisplay = p.foName.trimmingCharacters(in: .whitespaces) }
                    inviteSessionToken = nil
                    nuPinInvite = ""
                    nuPinInviteConfirm = ""
                    apiBanner = nil
                    onboardingStep = "complete"
                }
            }
        }
    }

    @MainActor
    private func refreshDashboardIfNeeded() async {
        guard liveMode, onboardingStep == "complete", let t = foScopedToken, !t.isEmpty else { return }
        async let hr = api.driverGetHome(t)
        async let pr = api.driverGetProfile(t)
        async let ar = api.driverGetAssignments(t)
        let h = await hr
        let p = await pr
        let a = await ar
        if case let .success(hv) = h { apiHome = hv } else if case let .failure(e) = h { apiBanner = ReactParityBanner.forGenericFailure(e) }
        if case let .success(pv) = p { apiProfile = pv }
        if case let .success(av) = a { apiAssignments = av } else if case let .failure(e) = a { apiBanner = ReactParityBanner.forGenericFailure(e) }
    }

    @MainActor
    private func loadTransactionsIfNeeded() async {
        guard liveMode, onboardingStep == "complete", let t = foScopedToken, !t.isEmpty else { return }
        guard let vid = vehicleIdForActive(bindingsEffective, activeCard), !vid.isEmpty else {
            recentLiveTx = []
            return
        }
        let pg = await api.driverGetTransactions(t, vehicleId: vid, page: 0)
        switch pg {
        case let .failure(e): apiBanner = ReactParityBanner.forGenericFailure(e)
        case let .success(txPage):
            recentLiveTx = txPage.rows.map { mapTxnRow($0) }
        }
    }

    private func mapTxnRow(_ row: DriverTxnRowParsed) -> DemoTxn {
        DemoTxn(
            id: row.serverTxnId,
            station: row.status.isEmpty ? "Fueling" : row.status,
            vrn: row.vehicleRegNo,
            amount: Int(abs(row.amountINR).rounded()),
            date: row.createdOn,
            type: row.status.uppercased().contains("CREDIT") ? "Credit" : "Fueling",
            status: row.status,
        )
    }

    private var effectiveMockSessionPin: String {
        rstPin.count == 6 ? rstPin : displayDriver.pin
    }

    private func resendLoginOtp() {
        apiBanner = nil
        if liveMode {
            Task { @MainActor in
                onboardingAction = "login_resend_otp"
                defer { onboardingAction = nil }
                switch await api.driverSendLoginOtp(mobile) {
                case let .failure(e): apiBanner = ReactParityBanner.forGenericFailure(e)
                case .success:
                    otpCountdown = 60
                    loginOtpRefocusKey += 1
                }
            }
        } else {
            otpCountdown = 30
        }
    }

    private func verifyLoginOtpTapped() {
        guard !liveMode else { return }
        let entered = otpDigits.joined()
        if entered == "123456" {
            otpError = ""
            if isRegistered {
                onboardingStep = "complete"
            } else {
                rstPin = ""
                rstPinConfirm = ""
                rstPinError = ""
                onboardingStep = "set_pin"
            }
        } else {
            otpError = "Incorrect OTP. Try again."
            otpDigits = Array(repeating: "", count: 6)
            loginOtpRefocusKey += 1
        }
    }

    private func submitConfirmPin() {
        if rstPinConfirm == rstPin {
            rstPinError = ""
            if !isRegistered {
                onboardingStep = "registered"
            } else {
                rstPin = ""
                rstPinConfirm = ""
                isRegistered = true
                successBanner = "PIN updated successfully."
                onboardingStep = "login"
            }
        } else {
            rstPinError = ReactParityBanner.pinsDidntMatchConfirm
            rstPinConfirm = ""
            onboardingStep = "set_pin"
        }
    }

    private func resendInviteOtp() {
        apiBanner = nil
        if liveMode {
            guard DriverFleetQr.validIndianMobile10(mobile) else { return }
            Task { @MainActor in
                onboardingAction = "invite_resend_otp"
                defer { onboardingAction = nil }
                switch await api.driverInviteMobileSendOtp(mobile) {
                case let .failure(e): apiBanner = ReactParityBanner.forGenericFailure(e)
                case let .success(ref):
                    inviteOtpRef = ref
                    otpCountdown = 60
                    inviteOtpRefocusKey += 1
                }
            }
        } else {
            otpCountdown = 30
        }
    }

    private func handleFleetpayQrScanned(_ raw: String) {
        guard selectedScan != nil || scanEligible.first != nil else {
            apiBanner = ReactParityBanner.selectVehicleFirst
            return
        }
        if let pq = DriverFleetQr.parseFleetpayPayUri(raw) {
            parsedScanQr = pq
            sessionIdle = false
            sessionPhase = "confirmation"
            apiBanner = nil
        } else {
            apiBanner = ReactParityBanner.invalidFleetpayQr
        }
    }

    private func verifyScanSessionPinTapped() {
        guard sessionPin.count == 6 else { return }
        if liveMode {
            Task { await verifyScanPinLive() }
        } else if sessionPin == effectiveMockSessionPin {
            sessionPin = ""
            sessionPhase = "otp_entry"
            scanSessionOtpCountdown = 60
        } else {
            sessionPin = ""
        }
    }

    @MainActor
    private func verifyLoginOtpLive() async {
        guard liveMode, onboardingAction == nil, onboardingStep == "login_otp" else { return }
        otpError = ""
        onboardingAction = "login_verify_otp"
        let otpStr = otpDigits.joined()
        let partial = await api.driverOauthOtpGrant(mobile: mobile, otp: otpStr)
        switch partial {
        case let .failure(e):
            apiBanner = ReactParityBanner.forOtpFailure(e)
            otpError = ""
            otpDigits = Array(repeating: "", count: 6)
            focusedOtpDigitIndex = 0
            onboardingAction = nil
            return
        case let .success(pTok):
            otpPhaseToken = pTok
            let fos = await api.driverFoList(pTok)
            switch fos {
            case let .failure(e):
                apiBanner = ReactParityBanner.forOtpFailure(e)
                otpError = ""
                otpPhaseToken = nil
                otpDigits = Array(repeating: "", count: 6)
                focusedOtpDigitIndex = 0
            case let .success(list):
                let active = list.filter { $0.foStatus == "ACTIVE" }
                if active.isEmpty {
                    apiBanner = ReactParityBanner.noActiveFleet
                    otpPhaseToken = nil
                    otpDigits = Array(repeating: "", count: 6)
                    focusedOtpDigitIndex = 0
                } else if active.count == 1 {
                    selectedFoCompanyId = active[0].foCompanyId
                    fleetPinFoDisplay = active[0].foName
                    foPinEntry = ""
                    onboardingStep = "fo_pin_login"
                    otpDigits = Array(repeating: "", count: 6)
                } else {
                    foOrganizationList = list
                    selectedFoCompanyId = nil
                    onboardingStep = "select_fo"
                    otpDigits = Array(repeating: "", count: 6)
                }
            }
            onboardingAction = nil
        }
    }

    @MainActor
    private func verifyScanPinLive() async {
        guard liveMode, let tok = foScopedToken else { return }
        let veh = selectedScan ?? scanEligible.first
        guard let veh, let qr = parsedScanQr, sessionPin.count == 6 else { return }
        qrPayBusy = true
        defer { qrPayBusy = false }
        let vrn = DriverFleetQr.normVrnForQrPay(veh.vrn)
        let pay =
            await api.driverQrPay(
                tok,
                txnId: qr.txnId,
                vehicleRegNoNorm: vrn,
                pin: sessionPin,
                mid: qr.mid,
                terminalId: qr.terminalId,
                amountPaise: qr.amountPaise,
                expiryEpoch: qr.expiryEpoch,
                sign: qr.sign,
            )
        switch pay {
        case let .failure(e):
            apiBanner = ReactParityBanner.forPinFailure(e)
            sessionPin = ""
        case let .success(result):
            lastQrPay = result
            sessionPin = ""
            sessionPhase = "complete"
            if case let .success(h) = await api.driverGetHome(tok) { apiHome = h }
            let vidChosen = vehicleIdForActive(bindingsEffective, activeCard)
            let vidFb = veh.vehicleId.trimmingCharacters(in: .whitespaces)
            let vid: String? = {
                if let vc = vidChosen, !vc.isEmpty { return vc }
                if !vidFb.isEmpty { return vidFb }
                return nil
            }()
            if let vid {
                if case let .success(pg) = await api.driverGetTransactions(tok, vehicleId: vid, page: 0) {
                    recentLiveTx = pg.rows.map { mapTxnRow($0) }
                }
            }
        }
    }

    private func vehicleIdForActive(_ binds: [DemoBinding], _ idx: Int) -> String? {
        let cards = binds.filter { $0.paired && $0.state == .active }
        guard idx >= 0, idx < cards.count else { return nil }
        let v = cards[idx].vehicleId.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    private static func initials(of name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ").map(String.init)
        switch parts.count {
        case 0: return "?"
        case 1: return String(parts[0].prefix(2)).uppercased(with: Locale(identifier: "en_US"))
        default: return (parts[0].prefix(1) + parts[1].prefix(1)).uppercased(with: Locale(identifier: "en_US"))
        }
    }

    private var assignmentsSectioned: some View {
        let binds = bindingsEffective
        let active = binds.filter { $0.paired && $0.state == .active }
        let pend = binds.filter { $0.state == .pendingAcceptance }
        let repair = binds.filter { $0.scanPayStatus == "locked_repair" }
        let needs = pend.count + repair.count
        let green = Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("My Vehicles").font(.title).bold()
                Text("\(active.count) active · \(needs) need attention")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(active) { b in
                    assignmentActiveCard(b, green: green)
                }

                if needs > 0 {
                    Text("NEEDS ATTENTION")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255))
                        .padding(.top, 4)
                    ForEach(pend) { b in
                        assignmentPendingCard(b, green: green)
                    }
                    ForEach(repair) { b in
                        assignmentRepairCard(b, green: green)
                    }
                }

                if active.isEmpty, pend.isEmpty, repair.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No vehicles yet").font(.headline)
                        Text("Your Fleet Operator will assign vehicles here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
            .padding(16)
        }
    }

    private func assignmentActiveCard(_ b: DemoBinding, green: Color) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255)).frame(height: 8)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(b.vrn).font(.title3.bold().monospaced())
                    Spacer()
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .overlay(Capsule().stroke(green, lineWidth: 1))
                }
                Text(b.fo.isEmpty ? "—" : b.fo).font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    Text("Balance").foregroundStyle(.secondary)
                    Spacer()
                    Text("₹\(b.balance)").font(.title2.bold())
                }
            }
            .padding(20)
            Divider()
            HStack {
                assignmentAction("Scan & Pay", systemImage: "qrcode", enabled: !scanPayDisabled(b), tint: green) {
                    openScanForBinding(b)
                }
                assignmentAction("Transactions", systemImage: "list.bullet") {
                    openTransactionsForBinding(b)
                }
                assignmentAction("Details", systemImage: "info.circle") {
                    detailBinding = b
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
    }

    private func assignmentPendingCard(_ b: DemoBinding, green: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(b.vrn).font(.headline.monospaced())
            Text(b.fo).font(.caption).foregroundStyle(.secondary)
            Text("Pairing required — accept to activate fueling.")
                .font(.caption)
                .foregroundStyle(Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255))
            Button("Accept & Pair") { openAssignmentNotification(b) }
                .buttonStyle(.borderedProminent)
                .tint(green)
            Button("Decline") {
                assignmentPick = b
                showDeclineConfirm = true
            }
            .foregroundStyle(.red)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.35), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func assignmentRepairCard(_ b: DemoBinding, green: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(b.vrn).font(.headline.monospaced())
            Text(b.fo).font(.caption).foregroundStyle(.secondary)
            Text("Re-pair required before Scan & Pay.")
                .font(.caption)
                .foregroundStyle(.red)
            Button("Re-pair vehicle") { openPairingFor(b) }
                .buttonStyle(.borderedProminent)
                .tint(green)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.35), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func assignmentAction(
        _ title: String,
        systemImage: String,
        enabled: Bool = true,
        tint: Color = Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255),
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(enabled ? tint : .gray)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func assignmentDetailSheet(_ b: DemoBinding) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if b.authMode == .tripLinked {
                        detailRow("Vehicle", b.vrn)
                        detailRow("Date", b.tripDate)
                        detailRow("Window", "\(b.tripStart) – \(b.tripEnd)")
                        detailRow("From", b.origin.isEmpty ? "—" : b.origin)
                        detailRow("To", b.destination.isEmpty ? "—" : b.destination)
                    } else if b.authMode == .shiftBased {
                        ForEach(b.shiftDays, id: \.self) { day in
                            HStack {
                                Text(day)
                                Spacer()
                                Text("\(b.shiftStart) – \(b.shiftEnd)").monospaced()
                            }
                        }
                        if b.shiftDays.isEmpty {
                            Text("\(b.shiftStart) – \(b.shiftEnd)").monospaced()
                        }
                    } else {
                        detailRow("Balance", "₹\(b.balance)")
                        detailRow("Fleet Operator", b.fo.isEmpty ? "—" : b.fo)
                    }
                }
                .padding()
            }
            .navigationTitle(
                b.authMode == .tripLinked ? "Trip details" : b.authMode == .shiftBased ? "Shift schedule" : b.vrn,
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { detailBinding = nil }
                }
            }
        }
    }

    private func detailRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).fontWeight(.medium)
        }
    }

    private var profileTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(displayDriver.initials)
                        .font(.title2.bold())
                        .frame(width: 64, height: 64)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundStyle(Color.green)
                    Text(displayDriver.name).font(.title3.bold())
                    Text(profileSubtitle).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Account")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    Divider()
                    profileRow("Mobile", displayDriver.maskedMobile)
                    Divider()
                    profileRow("Registered", profileRegisteredLine())
                    Divider()
                    profileRow("Fleet Operator", fleetOperatorDisplay)
                    Divider()
                    profileRow("Driver ID", driverIdLine)
                    Divider()
                    profileRow("Licence Number", licenceLine)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                if liveMode, foScopedToken != nil, effectiveFoCompanyIdForPin != nil {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Security")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                        Divider()
                        Button {
                            apiBanner = nil
                            successBanner = nil
                            profilePinModalOpen = true
                        } label: {
                            HStack {
                                Text("Change PIN").font(.subheadline.weight(.medium))
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                }
                if !profileVehicleRows.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("My Vehicles")
                            .font(.headline)
                            .padding()
                        Divider()
                        ForEach(Array(profileVehicleRows.enumerated()), id: \.offset) { i, row in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(row.0).font(.subheadline.weight(.medium))
                                HStack(spacing: 8) {
                                    Text(row.1)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.green)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.green.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                }
                            }
                            .padding()
                            if i < profileVehicleRows.count - 1 { Divider() }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))
                }
                Button("Sign out") {
                    onFinish(.success(event: "FLEET_FLOW_COMPLETED", payload: ["reason": "logout"]))
                }
                .buttonStyle(.bordered)
                .tint(Color.red)
                .padding(.top, 8)
            }
            .padding(16)
        }
    }

    private var profileVehicleRows: [(String, String)] {
        if !apiAssignments.isEmpty {
            return apiAssignments.map { ($0.vehicleRegNo, $0.status) }
        }
        return activeCards.map { ($0.vrn, "ACTIVE") }
    }

    private func profileRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(v).font(.subheadline.weight(.medium)).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func iosTabItem(_ index: Int, _ systemImage: String, _ title: String) -> some View {
        let tint = Color(red: 4 / 255, green: 120 / 255, blue: 87 / 255)
        let inactive = Color.gray
        let on = navHighlightIndex == index
        return Button {
            mainContent = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 10, weight: on ? .medium : .regular))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(on ? tint : inactive)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}

/// Matches `app/page.tsx` fixed feedback banner (error: amber · success: green; scroll, Dismiss).
private enum FleetApiFeedbackTone {
    case error
    case success
}

private struct FleetApiFeedbackBanner: View {
    let message: String
    let tone: FleetApiFeedbackTone
    let onDismiss: () -> Void

    private static let amber50 = Color(red: 1, green: 0.984, blue: 0.922)
    private static let amber200 = Color(red: 0.992, green: 0.902, blue: 0.541)
    private static let amber700 = Color(red: 0.706, green: 0.325, blue: 0.024)
    private static let amber900 = Color(red: 0.471, green: 0.231, blue: 0.059)
    private static let amber950 = Color(red: 0.271, green: 0.102, blue: 0.012)

    private static let green50 = Color(red: 240 / 255, green: 253 / 255, blue: 244 / 255)
    private static let green200 = Color(red: 187 / 255, green: 247 / 255, blue: 208 / 255)
    private static let green700 = Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255)
    private static let green900 = Color(red: 22 / 255, green: 101 / 255, blue: 52 / 255)
    private static let green950 = Color(red: 20 / 255, green: 83 / 255, blue: 45 / 255)

    private var bg: Color {
        switch tone {
        case .error: Self.amber50
        case .success: Self.green50
        }
    }

    private var stroke: Color {
        switch tone {
        case .error: Self.amber200
        case .success: Self.green200
        }
    }

    private var iconName: String {
        switch tone {
        case .error: "exclamationmark.circle.fill"
        case .success: "checkmark.circle.fill"
        }
    }

    private var iconTint: Color {
        switch tone {
        case .error: Self.amber700
        case .success: Self.green700
        }
    }

    private var textTint: Color {
        switch tone {
        case .error: Self.amber950
        case .success: Self.green950
        }
    }

    private var dismissTint: Color {
        switch tone {
        case .error: Self.amber900
        case .success: Self.green900
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(iconTint)
            ScrollView {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(textTint)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
            Button("Dismiss", action: onDismiss)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(dismissTint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(stroke, lineWidth: 1),
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
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
