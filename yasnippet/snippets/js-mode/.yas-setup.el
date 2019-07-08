(defcustom akirak/js-require-trailing-semicolon t
  "Non-nil if each statement should be ended with semicolon."
  :type 'boolean)

(make-variable-buffer-local 'akirak/js-require-trailing-semicolon)

(defun akirak/js-trailing-semicolon-if-desired ()
  (if akirak/js-require-trailing-semicolon ";" ""))

(defcustom akirak/js-preferred-quote "'"
  "Quote character used by snippets in js-mode."
  :type 'string)

(make-variable-buffer-local 'akirak/js-preferred-quote)
