;; $Id: regexmatch-mzscheme.code,v 1.9 2006/06/21 15:05:29 bfulgham Exp $
;;; http://shootout.alioth.debian.org/
;;;
;;; Based on the Chicken implementation
;;; Contributed by Brent Fulgham

;; Uses byte regexps instead of string regexps for a fairer comparison

;; NOTE: the running time of this benchmark is dominated by
;; construction of the `num' string.

(require racket/match)

(define rx
  (string-append
   "(?:^|[^0-9\\(])"                    ; (1) preceding non-digit or bol
   "("                                  ; (2) area code
   "\\(([0-9][0-9][0-9])\\)"            ; (3) is either 3 digits in parens
   "|"                                  ; or
   "([0-9][0-9][0-9])"                  ; (4) just 3 digits
   ")"                                  ; end of area code
   " "                                  ; area code is followed by one space
   "([0-9][0-9][0-9])"                  ; (5) exchange is 3 digits
   "[ -]"                               ; separator is either space or dash
   "([0-9][0-9][0-9][0-9])"             ; (6) last 4 digits
   "(?:[^0-9]|$)"                       ; must be followed by a non-digit
   ))


(: main ((Vectorof String) -> Void))
(define (main args)
  (let: ((n : String
            (if (= (vector-length args) 0)
                "1"
                (vector-ref args 0)))
        (phonelines : (Listof Bytes) '())
        (rx : Byte-Regexp (byte-regexp (string->bytes/utf-8 rx)))
        (count : Integer 0))
    (let: loop : False
          ((line : (U Bytes EOF) (read-bytes-line)))
      (cond ((eof-object? line) #f)
            (else
             (set! phonelines (cons line phonelines))
             (loop (read-bytes-line)))))
    (set! phonelines (reverse phonelines))
    (do ([n (assert (string->number n) exact-integer?)
            (sub1 n)])
        ((negative? n))
      (let loop ((phones phonelines)
                 (count 0))
        (if (null? phones)
            count
            (let: ([m : (Option (Listof (Option Bytes)))
                      (regexp-match rx (car phones))])
              (if m
                  (match-let ([(list a1 a2 a3 exch numb) (cdr m)])
                    (let* ([area (and a1 (or a2 a3))]
                           [num (bytes-append #"(" (assert area) #") "
                                              (assert exch) #"-"
                                              (assert numb))]
                           [count (add1 count)])
                      (when (zero? n)
                        (printf "~a: ~a\n" count num))
                      (loop (cdr phones) count)))
                  (loop (cdr phones) count))))))))

(main (current-command-line-arguments))
