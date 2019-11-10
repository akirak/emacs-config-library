;;; obsolete-org-config.el --- My archive for obsolete org configuration -*- lexical-binding: t -*-
;;;; Org-capture
;;;;; Capturing into the clocked task

;; Inspired by http://www.howardism.org/Technical/Emacs/capturing-content.html

;;;;;; Plain content
(org-starter-def-capture "a" "Current clock")

(add-to-list 'org-capture-templates-contexts
             '("a" ((lambda () (org-clocking-p)))))

(org-starter-def-capture "ap" "Plain content"
  plain (clock)
  "%?%i" :unnarrowed t :empty-lines 1 :no-save t)

(org-starter-def-capture "aP" "Plain content (immediate finish)"
  plain (clock)
  "%i" :immediate-finish t :empty-lines 1 :no-save t)

(defsubst akirak/org-capture-plain (&rest paragraphs)
  (org-capture-string (mapconcat #'identity (delq nil paragraphs)
                                 "\n\n")
                      "aP"))

(defsubst akirak/org-capture-plain-popup (&rest paragraphs)
  (org-capture-string (concat "  "
                              (mapconcat #'identity (delq nil paragraphs)
                                         "\n\n"))
                      "ap"))

;;;;;; Item
(org-starter-def-capture "ai" "List item"
  item (clock)
  "%?"  :no-save t :unnarrowed t)

(org-starter-def-capture "aI" "List item (immediate finish)"
  item (clock)
  "%i" :immediate-finish t :no-save t)

(defsubst akirak/org-capture-item (input)
  (org-capture-string input "aI"))

(org-starter-def-capture "ab" "List item with checkbox"
  checkitem (clock)
  "[ ] %?"  :no-save t :unnarrowed t)

;;;;;; Child entries
(org-starter-def-capture "as" "Subtree"
  entry (clock)
  "* %^{Title}
:PROPERTIES:
:CREATED_TIME: %U
:END:
%?"
  :clock-in t :clock-resume t :no-save t :empty-lines 1)

(org-starter-def-capture "aS" "Subtree (immediate finish, clock-in)"
  entry (clock)
  "* ^{Title}
:PROPERTIES:
:CREATED_TIME: %U
:END:"
  :clock-in t :immediate-finish t :no-save t :empty-lines 1)

(org-starter-def-capture "aH" "Heading (immediate finish, clock-in)"
  entry (clock)
  "* %i"
  :clock-in t :immediate-finish t :no-save t)


(provide 'obsolete-org-config)
;;; obsolete-org-config.el ends here
