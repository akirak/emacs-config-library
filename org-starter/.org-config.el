;;;; Todo states

(defun akirak//org-todo-keyword-names ()
  (cl-loop for (type . group) in org-todo-keywords
           when (eq type 'sequence)
           append (cl-loop for spec in group
                           unless (equal spec "|")
                           collect (replace-regexp-in-string "(.+)$" "" spec))))

(setq-default org-todo-keywords
              '((sequence
                 "TODO(t)"
                 "NEXT(n!)"
                 "STARTED(s!)"
                 "REVIEW(r!)" ; I probably need to review my task after working on it
                 "|"
                 "DONE(d)")
                (sequence
                 "MAYBE(m@)"
                 ;; Probably deprecated soon
                 "BLOCKED(b@/!)"
                 "DEPRECATED(D@/!)"
                 "WAITING(w@/!)" ; Waiting for a particular starting time.
                 "URGENT(u!/)"
                 "|"
                 "ARCHIVED(a@/!)")
                (type
                 "TO_BLOG(l)"
                 "HABIT(h)"
                 "EXPLORE(x)"
                 ;; Define these tags precisely
                 "TOPIC(o)"
                 "FIX(f)"
                 "IDEA(i)")))

(setq-default org-todo-state-tags-triggers
              (append '(("ARCHIVED" ("ARCHIVE" . t))
                        ("EXPLORE" ("@explore" . t)))
                      (mapcar (lambda (kw)
                                `(,kw (,(concat "@" (downcase kw)) . t)))
                              '("FIX" "TOPIC"))))

(setq org-todo-keyword-faces
      `(("TODO" . (:foreground "SpringGreen2" :weight bold))
        ("NEXT" . (:foreground "yellow2" :weight bold))
        ("STARTED" . (:foreground "DarkOrange" :weight bold))
        ;; Warning
        ("URGENT" . (:foreground "red"))
        ("TOPIC" . (:foreground "LightSeaGreen" :weight bold))
        ("FIX" . (:foreground "VioletRed4" :weight bold))
        ;; Review and to_blog: italicized
        ("REVIEW" . (:foreground "orange1" :slant italic))
        ("TO_BLOG" . (:foreground "LightGoldenrod" :slant italic :weight bold))
        ;; Done-like states
        ("DONE" . (:foreground "ForestGreen"))
        ("ARCHIVED" . (:foreground "DarkGrey" :underline t))
        ;; Deprecated, but similar to ARCHIVED
        ("CANCELLED" . (:foreground "DarkGrey" :underline t))
        ;; Inactive states
        ("BLOCKED" . (:foreground "IndianRed1" :weight bold :underline t))
        ("WAITING" . (:foreground "MediumPurple2" :weight bold :underline t))
        ("MAYBE" . (:foreground "LimeGreen" :underline t))))

(defun akirak/clock-in-to-next (kw)
  "Switch a task from TODO to IN_PROGRESS when clocking in.
Skips capture tasks, projects, and subprojects."
  (when (and (not (and (boundp 'org-capture-mode) org-capture-mode))
             (not (equal (org-entry-get nil "STYLE") "habit")))
    (cond
     ((member (org-get-todo-state) (list "TODO" "NEXT" "WAITING"))
      "STARTED"))))

(setq-default org-clock-in-switch-to-state #'akirak/clock-in-to-next)

;;;; Files

;;;;; Commonplace book
(org-starter-define-file "cpb.org"
  :key "c"
  :refile (org-starter-extras-def-reverse-datetree-refile "cpb.org"
            '("CREATED_TIME" "CREATED_AT" "CLOSED")))

(org-starter-def-capture "c" "cpb.org: Plain entry"
  entry (file+function "cpb.org" org-reverse-datetree-goto-date-in-file)
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:

%(unless (string-empty-p \"%i\") \"%i\n\n\")%?"
  :clock-in t :clock-resume t :empty-lines 1)

(org-starter-add-agenda-custom-command
    "c" "Browse entries in cpb.org"
  (lambda (_)
    (org-ql-agenda (org-starter-locate-file "cpb.org" nil t)
      (level 4)
      :sort priority))
  ""
  '((org-super-agenda-groups
     '((:todo "DONE")
       (:todo t)))))

;;;;; Local files
;; To avoid synchronization conflicts, I add new entries to this file
;; and usually not to other files when I am on my phone.
;; When I am on my computer, I refile entries in this file to other
;; permanent files.

(org-starter-def "inbox-phone.org"
  :agenda t)

(org-starter-def "inbox-tablet.org"
  :agenda t)

;;;;; Other personal Org files

(org-starter-def "devel.org"
  :key "d"
  :agenda t
  :refile (:maxlevel . 3))

(org-starter-def "learning.org"
  :key "l"
  :agenda t
  :refile (:maxlevel . 5))

(org-starter-def "references.org"
  :key "r"
  :agenda t
  :refile (:maxlevel . 9))

(org-starter-define-file "devlog.org"
  :key "g"
  :agenda nil
  :local-variables
  '((org-reverse-datetree-level-formats
     . '("%Y"
         (lambda (time)
           (format-time-string "%Y-%m %B"
                               (org-reverse-datetree-monday time)))
         "%Y W%W"
         "%Y-%m-%d %A")))
  :refile
  (org-starter-extras-def-reverse-datetree-refile "devlog.org"
    '("CREATED_TIME" "CREATED_AT" "CLOSED")))

(org-starter-def-capture "d" "devlog.org: Plain entry"
  entry (file+function "devlog.org" org-reverse-datetree-goto-date-in-file)
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:

%(unless (string-empty-p \"%i\") \"%i\n\n\")%?"
  :clock-in t :clock-resume t :empty-lines 1)

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

(org-starter-def-capture "?" "Subtree in this file"
  entry (function (lambda () (counsel-org-goto)))
  "* %^{Heading}
:PROPERTIES:
:CREATED_TIME: %U
:END:

%(unless (string-empty-p \"%i\") \"%i\n\n\")%?"
  :clock-in t :clock-resume t :empty-lines 1)

(add-to-list 'org-capture-templates-contexts
             '(("?" ((in-mode . org-mode)))))

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
