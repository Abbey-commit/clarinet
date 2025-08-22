;; contracts/sbtc-borrow-lend.clar

;; Define a fungible token (sbtc in this case)
(define-fungible-token sbtc)

;; Store the current borrower (if any)
(define-data-var borrower (optional principal) none)

;; Store amount borrowed
(define-data-var borrowed-amount uint u0)

;; Lend sBTC to a borrower
(define-public (lend (amount uint) (borrower-address principal))
    (begin
        ;; transfer sBTC from lender (tx-sender) to borrower
        (try! (ft-transfer? sbtc amount tx-sender borrower-address))
        ;; record borrower add amount
        (var-set borrower (some borrower-address))
        (var-set borrowed-amount amount)
        (ok true)
    )
)

;; repay borrowed tokens
(define-public (repay (amount uint))
    (let ((current-borrower (var-get borrower)))
        (match current-borrower
            borrower-principal
            (begin
                ;; transfer repayment from borrower to lender
                (try! (ft-transfer? sbtc amount tx-sender borrower-principal))
                ;; reset state
                (var-set borrowed-amount u0)
                (var-set borrower none)
                (ok true)
            )
            ;; if no borrower is set
            (err u100) ;; error code for "no active loan"
        )
    )
)