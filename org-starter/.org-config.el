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
                 "ALTERNATIVE(L)"
                 "STOPPED(p@)"
                 "WAITING(w@/!)")
                (type
                 "REQ_SENT(S@/)"
                 "|"
                 "APPROVED(A!)"
                 "REJECTED(R@/!)")
                (sequence
                 "HABIT(h)"
                 "|"
                 "HABIT_INACTIVE(i)")))

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

;;;; Org files in this repository
;;;;; yankpad.org
(org-starter-define-file (expand-file-name "yankpad/yankpad.org" no-littering-etc-directory)
  :key "y"
  :custom-vars 'yankpad-file)

;;;;; emacs-journal.org
(org-starter-define-file "emacs-journal.org"
  :key "E"
  :refile
  (org-starter-extras-def-reverse-datetree-refile "emacs-journal.org"
    '("CREATED_TIME" "CREATED_AT" "CLOSED"))
  :local-variables
  '((org-reverse-datetree-level-formats
     . ((lambda (time) (format-time-string "%Y-%m"))
        "%Y-%m-%d %A"))))

(org-starter-def-capture "je" "Emacs Journal"
  entry (file+function "emacs-journal.org" org-reverse-datetree-goto-date-in-file)
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:")

;;;; Utilities for org-agenda
(defmacro akirak/org-super-agenda-def-map-level (level)
  `(defun ,(intern (format "akirak/org-super-agenda-map-level-%s" level)) (item)
     (let ((marker (or (get-text-property 0 'org-marker item)
                       (get-text-property 0 'org-hd-marker item))))
       (with-current-buffer (marker-buffer marker)
         (save-excursion
           (goto-char marker)
           (nth ,(1- level) (org-get-outline-path nil t)))))))

(akirak/org-super-agenda-def-map-level 2)

(defun akirak/org-super-agenda-map-outline-path-cdr (item)
  (let ((marker (or (get-text-property 0 'org-marker item)
                    (get-text-property 0 'org-hd-marker item))))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (org-format-outline-path
         (cdr (org-get-outline-path nil t)))))))

(defun akirak/org-super-agenda-map-filenames (item)
  (when-let* ((marker (or (get-text-property 0 'org-marker item)
                          (get-text-property 0 'org-hd-marker item)))
              (buffer (marker-buffer marker))
              (filename (buffer-file-name buffer)))
    (file-name-nondirectory filename)))

(defun akirak/org-super-agenda-map-outline-path (item)
  (let ((marker (or (get-text-property 0 'org-marker item)
                    (get-text-property 0 'org-hd-marker item))))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (org-format-outline-path
         (org-get-outline-path nil t))))))

(defun akirak/org-super-agenda-map-outline-paths-with-filenames (item)
  (let ((marker (or (get-text-property 0 'org-marker item)
                    (get-text-property 0 'org-hd-marker item))))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (let ((filename (buffer-file-name (current-buffer)))
              (outline (org-format-outline-path
                        (org-get-outline-path nil t))))
          (if filename
              (concat (file-name-nondirectory filename) ": " outline)
            outline))))))

(defun akirak/org-super-agenda-map-top-level (item)
  (let ((marker (or (get-text-property 0 'org-marker item)
                    (get-text-property 0 'org-hd-marker item))))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (re-search-backward (rx bol "* "))
        (nth 4 (org-heading-components))))))

;;;; Org-Capture
;;;;; Utilities
(defun akirak/org-capture-select-refile-target ()
  (org-refile '(4)))

(defun akirak/org-src-language-of-file (file)
  (let ((buffer (find-buffer-visiting file)))
    (string-remove-suffix
     "-mode" (symbol-name (buffer-local-value 'major-mode buffer)))))

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

;;;; Other utiltiies

(defun akirak/org-sort-top-level-headings-alphabetically ()
  (let ((start-heading (nth 4 (org-heading-components)))
        (line (thing-at-point 'line))
        (col (car (posn-col-row (posn-at-point (point))))))
    (save-restriction
      (widen)
      (save-excursion
        (goto-char (point-min))
        (org-sort-entries nil ?a)))
    (goto-char (point-min))
    (re-search-forward (regexp-quote start-heading))
    (beginning-of-line)
    (re-search-forward (regexp-quote line))
    (move-to-column col)))
