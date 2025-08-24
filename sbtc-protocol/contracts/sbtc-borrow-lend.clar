;; contracts/sbtc-borrow-lend.clar

;; Define a fungible token (sbtc in this case)
(define-fungible-token sbtc)

;; Store the current borrower (if any)
(define-data-var borrower (optional principal) none)

;; Store amount borrowed
(define-data-var borrowed-amount uint u0)

;; Store the lender address
(define-data-var lender (optional principal) none)

;; Error codes
;; u100: No active loan
;; u101: Amount must be greater than 0
;; u102: Active loan already exists
;; u103: Cannot lend to yourself
;; u104: Only borrower can repay
;; u105: Repay amount must equal borrowed amount
;; u106: No lender found

;; Lend sBTC to a borrower
(define-public (lend (amount uint) (borrower-address principal))
    (begin
        ;; Input validation
        (asserts! (> amount u0) (err u101))
        (asserts! (is-none (var-get borrower)) (err u102))
        (asserts! (not (is-eq tx-sender borrower-address)) (err u103))
        
        ;; transfer sBTC from lender to borrower
        (try! (ft-transfer? sbtc amount tx-sender borrower-address))
        
        ;; Update state variables
        (var-set borrower (some borrower-address))
        (var-set borrowed-amount amount)
        (var-set lender (some tx-sender))
        
        (ok true)
    )
)

;; Repay borrowed tokens
(define-public (repay (amount uint))
    (let ((current-borrower (var-get borrower))
          (current-amount (var-get borrowed-amount))
          (current-lender (var-get lender)))
        
        ;; Input validation
        (asserts! (> amount u0) (err u101))
        (asserts! (is-some current-borrower) (err u100))
        (asserts! (is-some current-lender) (err u106))
        
        ;; Only borrower can repay
        (asserts! (is-eq tx-sender (unwrap-panic current-borrower)) (err u104))
        
        ;; Amount must match borrowed amount
        (asserts! (is-eq amount current-amount) (err u105))
        
        ;; Transfer repayment back to lender
        (try! (ft-transfer? sbtc amount tx-sender (unwrap-panic current-lender)))
        
        ;; Reset state
        (var-set borrowed-amount u0)
        (var-set borrower none)
        (var-set lender none)
        
        (ok true)
    )
)

;; Read-only functions for querying state
(define-read-only (get-borrower)
    (var-get borrower)
)

(define-read-only (get-borrowed-amount)
    (var-get borrowed-amount)
)

(define-read-only (get-lender)
    (var-get lender)
)