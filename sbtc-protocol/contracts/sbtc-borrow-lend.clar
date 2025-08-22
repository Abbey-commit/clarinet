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
;; u104: Repay amount must be greater than 0
;; u105: Only borrower can repay
;; u106: Repay amount must equal borrowed amount

;; Lend sBTC to a borrower
(define-public (lend (amount uint) (borrower-address principal))
    (begin
        ;; Input validation
        (asserts! (> amount u0) (err u101)) ;; amount must be greater than 0
        (asserts! (is-none (var-get borrower)) (err u102)) ;; no active loan should exist
        (asserts! (not (is-eq tx-sender borrower-address)) (err u103)) ;; cannot lend to yourself
        
        ;; transfer sBTC from lender (tx-sender) to borrower
        (try! (ft-transfer? sbtc amount tx-sender borrower-address))
        ;; record borrower, amount, and lender
        (var-set borrower (some borrower-address))
        (var-set borrowed-amount amount)
        (var-set lender (some tx-sender))
        (ok true)
    )
)

;; Repay borrowed tokens
(define-public (repay (amount uint))
    (let ((current-borrower (var-get borrower))
          (current-borrowed-amount (var-get borrowed-amount))
          (current-lender (var-get lender)))
        ;; Input validation
        (asserts! (> amount u0) (err u104)) ;; amount must be greater than 0
        (asserts! (is-some current-borrower) (err u100)) ;; must have active loan
        
        (match current-borrower
            borrower-principal
            (begin
                ;; Only the borrower can repay
                (asserts! (is-eq tx-sender borrower-principal) (err u105))
                ;; Amount must match borrowed amount (for simplicity)
                (asserts! (is-eq amount current-borrowed-amount) (err u106))
                
                ;; transfer repayment from borrower back to original lender
                (match current-lender
                    lender-address
                    (try! (ft-transfer? sbtc amount tx-sender lender-address))
                    (err u107) ;; No lender found
                )
                ;; reset state
                (var-set borrowed-amount u0)
                (var-set borrower none)
                (var-set lender none)
                (ok true)
            )
            ;; if no borrower is set
            (err u100) ;; error code for "no active loan"
        )
    )
)