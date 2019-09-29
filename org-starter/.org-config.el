;;;; Todo states

(setq-default org-todo-keywords
              '((sequence
                 "TODO(t)"
                 "NEXT(n!)"
                 "STARTED(s!)"
                 "REVIEW(r!)"
                 "|"
                 "DONE(d)"
                 "ARCHIVED(a@/!)")
                (sequence
                 "MAYBE(m@)"
                 "STOPPED(p@)"
                 "WAITING(w@/!)")))

(setq-default org-todo-state-tags-triggers
              (append '(("ARCHIVED" ("ARCHIVE" . t)))))

(setq org-todo-keyword-faces
      `(("TODO" . (:foreground "SpringGreen2" :weight bold))
        ("NEXT" . (:foreground "yellow2" :weight bold))
        ("STARTED" . (:foreground "DarkOrange" :weight bold))
        ;; Review and to_blog: italicized
        ("REVIEW" . (:foreground "orange1" :slant italic))
        ("TO_BLOG" . (:foreground "LightGoldenrod" :slant italic :weight bold))
        ;; Done-like states
        ("DONE" . (:foreground "ForestGreen"))
        ("ARCHIVED" . (:foreground "DarkGrey" :underline t))
        ;; Inactive states
        ("STOPPED" . (:foreground "DarkRed" :underline t))
        ("WAITING" . (:foreground "MediumPurple2" :weight bold :underline t))
        ("MAYBE" . (:foreground "LimeGreen" :underline t))))

(defun akirak/clock-in-to-next (kw)
  "Switch a task from TODO to IN_PROGRESS when clocking in.
Skips capture tasks, projects, and subprojects."
  (when (and (not (and (boundp 'org-capture-mode) org-capture-mode))
             (not (equal (org-entry-get nil "STYLE") "habit")))
    (cond
     ((member (org-get-todo-state) (list "TODO" "NEXT"))
      "STARTED"))))

(setq-default org-clock-in-switch-to-state #'akirak/clock-in-to-next)

;;;; Org files in this repositories
;;;;; yankpad.org
(org-starter-define-file (expand-file-name "yankpad/yankpad.org" no-littering-etc-directory)
  :key "y"
  :custom-vars 'yankpad-file)

;;;;; emacs-journal.org
(org-starter-define-file "emacs-journal.org"
  :key "e"
  :refile
  (org-starter-extras-def-reverse-datetree-refile "emacs-journal.org"
    '("CREATED_TIME" "CREATED_AT" "CLOSED"))
  :local-variables
  '((org-reverse-datetree-level-formats
     . ("%Y"
        (lambda (time)
          (format-time-string "%Y-%m %B"
                              (org-reverse-datetree-monday time)))
        "%Y W%W"
        "%Y-%m-%d %A"))))

(org-starter-def-capture "je" "Emacs Journal"
  entry (file+function "emacs-journal.org" org-reverse-datetree-goto-date-in-file)
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:")

;;;; Org-Capture
;;;;; Generic capture template
(org-starter-def-capture "/" "Subtree in a file"
  entry (function (lambda () (org-refile '(4))))
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:

%(unless (string-empty-p \"%i\") \"%i\n\n\")%?"
  :clock-in t :clock-resume t :empty-lines 1)

(org-starter-def-capture "'" "Avy target")

(defun akirak/avy-org-heading ()
  (avy-jump (rx bol (1+ "*") (1+ space))))

(org-starter-def-capture "'t" "Todo entry"
  entry (function akirak/avy-org-heading)
  "* TODO %?
:PROPERTIES:
:CREATED_TIME: %U
:END:
" :empty-lines 1)

(org-starter-def-capture "'d" "Heading with timestamp"
  entry (function akirak/avy-org-heading)
  "* %?
:PROPERTIES:
:CREATED_TIME: %U
:END:
")

(org-starter-def-capture "'h" "Heading without timestamp"
  entry (function akirak/avy-org-heading)
  "* %?")

(org-starter-def-capture "'i" "Item"
  item (function akirak/avy-org-heading)
  "- %?")

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

(org-starter-def-capture "ab" "Lite item with checkbox"
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

;;;;;; Interactive functions

;;;;;;; Blocks

;;;###autoload
(defun akirak/org-capture-selected-source (description with-link)
  (interactive (list (when current-prefix-arg
                       (read-string "Description: "))
                     (equal current-prefix-arg '(16))))
  (akirak/org-capture-plain description
                            (akirak/org-capture-wrap-selection "SRC"
                              (string-remove-suffix "-mode" (symbol-name major-mode)))
                            (when with-link
                              (concat "From "
                                      (akirak/location-as-org-link (akirak/describe-location-in-source))))))

;;;###autoload
(defun akirak/org-capture-selected-quote (description)
  (interactive (list (when current-prefix-arg
                       (read-string "Description: "))
                     (equal current-prefix-arg '(16))))
  (akirak/org-capture-plain description
                            (akirak/org-capture-wrap-selection "QUOTE")
                            (when with-link
                              (org-store-link nil)
                              (let ((org-keep-stored-link-after-insertion nil))
                                (concat "From "
                                        (org-make-link-string
                                         (car (pop org-stored-links))
                                         (buffer-name)))))))

;;;###autoload
(defun akirak/org-capture-selected-example (description)
  (interactive (list (when current-prefix-arg
                       (read-string "Description: "))
                     (equal current-prefix-arg '(16))))
  (akirak/org-capture-plain description
                            (akirak/org-capture-wrap-selection "EXAMPLE")))

;;;;; Clipboard

(org-starter-def-capture "b" "Bookmark")

;;;###autoload
(defun akirak/org-capture-clipboard-as-source (text lang url)
  (interactive (list (if current-prefix-arg
                         (completing-read "Kill ring: " (ring-elements kill-ring))
                       (funcall interprogram-paste-function))
                     (akirak/read-source-language "Language: ")
                     (clipurl-complete-url "Source URL of the code: ")))
  (akirak/org-capture-plain-popup
   (format "\n\n#+BEGIN_SRC %s\n%s\n#+END_SRC" lang text)
   (concat "From " (org-web-tools--org-link-for-url url))
   (akirak/org-capture-wrap-selection "SRC"
     (string-remove-suffix "-mode" (symbol-name major-mode)))
   (when with-link
     (concat "From "
             (akirak/location-as-org-link (akirak/describe-location-in-source))
             (org-make-link-string
              (car (pop org-stored-links))
              (akirak/describe-location-in-source))))))

;; TODO: Add quote

;; TODO: Add example

;;;;; Items

;;;###autoload
(defun akirak/org-capture-url-link-as-item (&optional url)
  (interactive)
  (unless (org-clocking-p)
    (user-error "Not clocking in"))
  (akirak/org-capture-item (org-web-tools--org-link-for-url url)))

;;;###autoload
(defun akirak/org-capture-string-as-item (text)
  (interactive (list (buffer-substring-no-properties
                      (region-beginning) (region-end))))
  (unless (org-clocking-p)
    (user-error "Not clocking in"))
  (akirak/org-capture-item text))

;;;;; Utility functions and macros

(defun akirak/org-capture-wrap-selection (type &rest plist)
  (declare (indent 1))
  (unless (stringp type)
    (user-error "TYPE must be string: %s" type))
  (format "#+BEGIN_%s%s\n%s\n#+END_%s"
          type
          (when plist
            (concat " " (mapconcat (lambda (s) (format "%s" s))
                                   plist " ")))
          (buffer-substring-no-properties (region-beginning)
                                          (region-end))
          type))

(defun akirak/location-as-org-link (&optional description)
  (org-store-link nil)
  (let ((org-keep-stored-link-after-insertion nil))
    (org-make-link-string (car (pop org-stored-links))
                          description)))

(defun akirak/describe-location-in-source ()
  (let* ((func (which-function))
         (abspath (expand-file-name (buffer-file-name)))
         ;; TODO: Add support for .svn
         (root (locate-dominating-file abspath ".git"))
         (filepath (if root
                       (file-relative-name abspath root)
                     (file-name-nondirectory abspath))))
    (if func
        (format "%s in %s" func filepath)
      filepath)))

(defun akirak/major-mode-list ()
  (let (modes)
    (do-all-symbols (sym)
      (let ((name (symbol-name sym)))
        (when (and (commandp sym)
                   (string-suffix-p "-mode" name)
                   (let ((case-fold-search nil))
                     (string-match-p "^[a-z]" name))
                   (not (string-match-p (rx "/") name))
                   (not (string-match-p "global" name))
                   (not (memq sym minor-mode-list)))
          (push sym modes))))
    modes))

(defun akirak/read-source-language (prompt)
  (completing-read prompt
                   (-sort #'string<
                          (--map (string-remove-suffix "-mode" (symbol-name it))
                                 (akirak/major-mode-list)))))
