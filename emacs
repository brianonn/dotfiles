;;; .emacs --- my initializations ---  -*- mode: emacs-lisp; -*-

;;; Author: Brian A. Onn
;;; Commentary:
;;; Change Log:

;;; TODO : change all (global-set-key ... ) to (define-key (current-global-map) key cmd)

;;; Code:

(prefer-coding-system 'utf-8)
(when (>= emacs-major-version 24)
    (setq-default buffer-file-coding-system 'utf-8)
    (setq default-buffer-file-coding-system 'utf-8))

(add-to-list 'load-path (concat user-emacs-directory "site-lisp"))

;; packages. Access with M-X package-list-packages
(when (>= emacs-major-version 24)
    (require 'package)
    (setq package-archives
        (append package-archives
            (list
                '("marmalade" . "http://marmalade-repo.org/packages/")
                '("melpa" . "http://melpa.org/packages/"))))
    (package-initialize)

    (defvar my/package-list
        '( auto-complete auto-complete-c-headers
             auto-complete-etags auto-complete-exuberant-ctags
             auto-dim-other-buffers
             company
             dart-mode
             dockerfile-mode
             editorconfig
             emmet-mode
             expand-region
             exec-path-from-shell
             fill-column-indicator
             flycheck
             go-mode golint go-scratch
             htmlize
             ibuffer
             iedit
             impatient-mode
             ivy counsel
             jade-mode
             js2-mode js2-refactor
             js3-mode
             json-mode json-reformat json-rpc
             lua-mode
             magit magithub
             markdown-mode pandoc-mode
             multiple-cursors mc-extras
             neotree
             nlinum
             nodejs-repl
             php-mode php+-mode
             rust rust-mode
             simple-httpd
             smartparens
             smart-mode-line
             smex
             sass-mode scss-mode
             sublimity
             tern tern-auto-complete
             use-package
             vue-mode vue-html
             web-mode
             xcscope
             yasnippet)
        "A list of packages that I want to always have installed.

     This is used by `my/install-packages' whenever I want to
     setup a new emacs deployment on a new host")

    (defvar my/packages-timestamp-file (concat user-emacs-directory "my-packages-timestamp"))
    (defvar my/packages-days-between-checks 7)

    (defun my/install-packages ()
        "Install the packages in the list `my/package-list'.
     This function can be called in .emacs just after `package-initialize'
     or it can be manually called only once when needed for a new deployment"
        (interactive)
        ;; TODO: create a timestamp file and only run through this code
        ;; on the first call (i.e. timestamp does not exist) or if the timestamp
        ;; is more than 1 week old
        (defvar my/packages-last-update (nth 5 (file-attributes my/packages-timestamp-file)))
        (defvar my/packages-elapsed-days (- (time-to-number-of-days (current-time))
                                             (time-to-number-of-days my/packages-last-update)))
        (if (or (not my/packages-last-update)
                (> my/packages-elapsed-days my/packages-days-between-checks))
            (progn
                (package-refresh-contents)
                (mapc (lambda (my/package)
                          (if (not (package-installed-p my/package))
                              (condition-case nil
                                  (package-install my/package)
                                  (error nil))))
                    my/package-list)
                (with-temp-buffer (write-file my/packages-timestamp-file)))))

    ;; run it
    (my/install-packages))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; lisp-mode settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(add-hook 'emacs-lisp-mode-hook
    (lambda ()
        ;; Use spaces, not tabs.
        (setq indent-tabs-mode nil)
        (setq tab-width 2)
        ;; Keep M-TAB for `completion-at-point'
        ;;(define-key flyspell-mode-map "\M-\t" nil)

        ;; Pretty-print eval'd expressions.
        (define-key emacs-lisp-mode-map (kbd "C-x C-e") nil)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e e") 'pp-eval-last-sexp)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e C-e") 'pp-eval-last-sexp)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e r") 'eval-region)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e C-r") 'eval-region)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e b") 'eval-buffer)
        (define-key emacs-lisp-mode-map (kbd "C-x C-e C-b") 'eval-buffer)

        ;; Recompile if .elc exists.
        ;; (add-hook 'after-save-hook
        ;;     (lambda ()
        ;;         (byte-force-recompile default-directory)) t t)
        (define-key emacs-lisp-mode-map
            "\r" 'reindent-then-newline-and-indent)))
(add-hook 'emacs-lisp-mode-hook 'eldoc-mode)
;;(add-hook 'emacs-lisp-mode-hook 'flyspell-prog-mode) ;; Requires Ispell


;; ========== MARKDOWN SUPPORT ===========
(require 'markdown-mode)
(require 'pandoc-mode)
(add-to-list 'auto-mode-alist `(,(rx ".md" string-end) . gfm-mode))
(add-hook 'markdown-mode-hook 'pandoc-mode)
(setq markdown-command "pandoc -c ~/.emacs.d/github-pandoc.css --from markdown_github -t html5 --mathjax --highlight-style pygments --standalone")


;; ;; ========== AUTO-DIM BUFFERS WITHOUT FOCUS ===========
;; (require 'auto-dim-other-buffers)
;; (add-hook 'after-init-hook
;;     (lambda ()
;;         (when (fboundp 'auto-dim-other-buffers-mode)
;;             (auto-dim-other-buffers-mode t))))

;; ========== INTERACTIVE DO COMPLETION=================

;; (require 'ido)
;; (ido-mode 1)
;; (setq ido-enable-flex-matching t)
;; (setq ido-everywhere t)
;; (setq ido-use-filename-at-point 'guess)
;; (setq ido-use-url-at-point t)
;; (setq ido-file-extensions-order '(".c" ".cpp" ".h" ".js" ".css" ".htm" ".html" ".txt"))

;; ========== IVY COMPLETION (REPLACES IDO) =============
(require 'ivy)
(ivy-mode t)
(setq ivy-use-virtual-buffers t)
(define-key global-map (kbd "C-s") 'swiper)
(global-set-key (kbd "C-c C-r") 'ivy-resume)
(global-set-key (kbd "<f6>") 'ivy-resume)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "<f1> f") 'counsel-describe-function)
(global-set-key (kbd "<f1> v") 'counsel-describe-variable)
(global-set-key (kbd "<f1> l") 'counsel-find-library)
;; removed f2 -- couldn't make it work
;;(global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
;;(global-set-key (kbd "<f2> u") 'counsel-unicode-char)
(global-set-key (kbd "C-c g") 'counsel-git)
(global-set-key (kbd "C-c j") 'counselgit-grep)
(global-set-key (kbd "C-c k") 'counsel-ag)
(global-set-key (kbd "C-x l") 'counsel-locate)
;(global-set-key (kbd "C-S-o") 'counsel-rhythmbox)
(define-key read-expression-map (kbd "C-r") 'counsel-expression-history)



;; ========== DIRED MODE ===========================

(require 'dired)
(define-key dired-mode-map "j" 'dired-next-line)
(define-key dired-mode-map "k" 'dired-previous-line)
(define-key dired-mode-map "S" 'dired-do-relsymlink)
(define-key dired-mode-map "i" 'ido-find-file)

;; create a file with capital 'C'
;; Copy files with lowercase 'c'
(eval-after-load 'dired
  '(progn
     (define-key dired-mode-map (kbd "C") 'my/dired-create-file)
     (define-key dired-mode-map (kbd "c") 'dired-do-copy)
     (defun my/dired-create-file (file)
       "Create a file called FILE. If FILE already exists, signal an error."
       (interactive
        (list (read-file-name "Create file: " (dired-current-directory))))
       (let* ((expanded (expand-file-name file))
              (try expanded)
              (dir (directory-file-name (file-name-directory expanded)))
              new)
         (if (file-exists-p expanded)
             (error "Cannot create file %s: file exists" expanded))
         ;; Find the topmost nonexistent parent dir (variable `new')
         (while (and try (not (file-exists-p try)) (not (equal new try)))
           (setq new try
                 try (directory-file-name (file-name-directory try))))
         (when (not (file-exists-p dir))
           (make-directory dir t))
         (write-region "" nil expanded t)
         (when new
           (dired-add-file new)
           (dired-move-to-filename))))))

;; [f8] starts neotree in the current directory
(defun my/dired-neotree-set-root ()
    "Start neotree in the current dired directory."
    (interactive)
    (save-selected-window
        (neo-global--open-dir (dired-current-directory))))
(define-key dired-mode-map [f8] 'my/dired-neotree-set-root)


;; ========== ORG MODE ===========================

(org-babel-do-load-languages
  'org-babel-load-languages
  '(
     (sh . t)
     (python . t)
     (ruby . t)
     (perl . t)
     ;;   (dart . t)
     ;;   (nim . t)
     (octave . t)
     ))

;; Add short cut keys for the org-agenda
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-ca" 'org-agenda)

;; ========== NEOTREE (Sidebar Tree) ===================

(require 'neotree)
(global-set-key [f8] 'neotree-toggle)

;; ========== EDITOR CONFIG ============================

(require 'editorconfig)
(editorconfig-mode 1)

;; ========== IBUFFER ==================================

(autoload 'ibuffer "ibuffer" "List Buffers Interactively" t)
(global-set-key (kbd "C-x C-b") 'ibuffer)
(defun my/ibuffer-set-columns ()
    ;; Use human readable Size column instead of original one
    (define-ibuffer-column prettysize
        (:name "Size" :inline t)
        (cond
            ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
            ((> (buffer-size) 100000) (format "%7.0fk" (/ (buffer-size) 1000.0)))
            ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
            (t (format "%8d" (buffer-size)))))

    ;; Modify the default ibuffer-formats
    (setq ibuffer-formats
        '((mark modified read-only " "
              (name 18 18 :left :elide)
              " "
              (prettysize 9 -1 :right)
              " "
              (mode 16 16 :left :elide)
              " "
              filename-and-process))))

(defun my/ibuffer-mode-hook ()
    (setq ibuffer-saved-filter-groups
        '(("home"
              ("Web Dev" (or (mode . html-mode)
                             (mode . web-mode)
                             (mode . css-mode)
                             (mode . jade-mode)
                             (mode . json-mode)
                             (mode . js-mode)
                             (mode . js2-mode)
                             (mode . js3-mode)))
              ("Solidity" (mode . solidity-mode))
              ("Magit" (name . "\*magit"))
              ("emacs-config" (or (filename . "\.emacs\.d")
                                  (filename . "emacs")
                                  (filename . "\.emacs")
                                  (filename . ".*\.el$")))
              ("Viacoin13" (filename . "/viacoin13.*/"))
              ("Viacoin" (filename . "/viacoin.*/"))
              ("Bitcoin" (filename . "/bitcoin.*/"))
              ("Dired"  (mode . dired-mode))
              ("Org" (or (mode . org-mode)
                         (filename . "OrgMode")
                         (filename . "org")))
              ("Help" (or (name . "\*Help\*")
                          (name . "\*Apropos\*")
                          (name . "\*info\*")))
              ("*temp*" (name . "^\*.*\*$")))))

    (ibuffer-switch-to-saved-filter-groups "home"))

(add-hook 'ibuffer-mode-hook 'my/ibuffer-mode-hook)

;; TODO - Ibuffer filters

;; ========== BLANK MODE ===============================

;;  (visualize blanks, tabs and newlines)
(if (require 'blank-mode "blank-mode" t)
    (progn
        (custom-set-variables
            '(blank-chars (quote (tabs spaces trailing lines space-before-tab newline empty space-after-tab)))
            '(blank-line-column 120))
        (global-blank-mode 0)
        (blank-mode 0)
        (global-set-key [f12] 'blank-mode)))


;; ========== xcsope mode ===============================

(if (require 'xcscope "xcscope" t)
    (progn
        (setq cscope-option-use-inverted-index t) ; use -q option on database
        (cscope-setup)
        (message "cscope done")))

;; ========== SUBLIMITY ================================

;; (require 'sublimity)
;; (sublimity-mode 1)

;; (require 'sublimity-scroll)
;; (setq sublimity-scroll-weight 10
;;       sublimity-scroll-drift-length 5)

;; (require 'sublimity-map)
;; (setq sublimity-map-size 20)
;; (setq sublimity-map-text-scale -7)
;; (setq sublimity-map-max-fraction 0.5)
;; (add-hook 'sublimity-map-setup-hook
;;           (lambda ()
;;             (setq buffer-face-mode-face '(:family "Monospace"))
;;             (buffer-face-mode)))

;; ;; (require 'sublimity-attractive)


;; =====================================================

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; new linum mode - faster than linum-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar nlinum-highlight-current-line t)
(defun initialize-nlinum (&optional frame)
  (require 'linum) ; for faces
  (require 'nlinum)
  (add-hook 'prog-mode-hook 'nlinum-mode))
(if (daemonp)
  (add-hook 'after-make-frame-functions 'initialize-nlinum)
  (add-hook 'after-init-hook 'initialize-nlinum))


;; from
;; https://github.com/alpaker/Fill-Column-Indicator/issues/67
(use-package fill-column-indicator
  :ensure t
  :init
    (setq-default fci-rule-column 90)
    (setq-default fci-rule-width 1)
    (setq-default fci-rule-color "grey24")
    (setq-default fci-rule-character 8286)          ; text modes use unicode vertical 4-ellipses
    (setq-default fci-rule-use-dashes t)            ; graphic modes use dashes
    (setq-default fci-dash-pattern 0.75)            ; graphic mode dash pattern
  :config
    (defvar eos/fci-disabled nil)
    (make-variable-buffer-local 'eos/fci-disabled)
    ;; Add a hook that disables fci if enabled when the window changes and it
    ;; isn't wide enough to display it.
    (defun eos/maybe-disable-fci ()
        "Disable `fill-column-indicator' if necessary."
        (interactive)
        ;; Disable FCI if necessary
        (when (and fci-mode
                  (< (window-width) (or fci-rule-column fill-column)))
            (fci-mode -1)
            (setq-local eos/fci-disabled t))
        ;; Enable FCI if necessary
        (when (and eos/fci-disabled
                  (eq fci-mode nil)
                  (> (window-width) (or fci-rule-column fill-column)))
            (fci-mode 1)
            (setq-local eos/fci-disabled nil)))

    (defun eos/add-fci-disabling-hook ()
        (interactive)
        (add-hook 'window-configuration-change-hook #'eos/maybe-disable-fci)
        (add-hook 'prog-mode-hook #'eos/add-fci-disabling-hook))
    (define-globalized-minor-mode global-fci-mode fci-mode
        (lambda ()
            (fci-mode 1)))
    (global-fci-mode 0))

;; unfill paragraph - useful for markdown docs
;;
;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph (&optional region)
    "Takes a multi-line paragraph and makes it into a single line of text."
    (interactive (progn (barf-if-buffer-read-only) '(t)))
    (let ((fill-column (point-max))
             ;; This would override `fill-column' if it's an integer.
             (emacs-lisp-docstring-fill-column t))
        (fill-paragraph nil region)))
;; Handy key definition
(define-key global-map "\M-S-q" 'unfill-paragraph)


;; ;; ========== ORIGAMI FOLDING =============
;; ;; hooks with fci-mode to disable it when folding
;; ;; and unfolding
;; (use-package origami
;;     :ensure t
;;     :bind (("C-<return>" . my/origami-toggle-node))
;;     :config
;;     (defvar o/test nil)
;;     (make-variable-buffer-local 'o/test)
;;     (defun my/origami-toggle-node ()
;;         (interactive)
;;         (if fci-mode
;;             (progn
;;                 (fci-mode -1)
;;                 (origami-toggle-node (current-buffer) (point))
;;                 (fci-mode 1))
;;             (origami-toggle-node (current-buffer) (point))))

;;     (add-hook 'prog-mode-hook #'origami-mode))


;; ========== hs-mode FOLDING =============
;; hooks with fci-mode to disable it when folding
;; and unfolding
(use-package hideshow
    :ensure t
    :bind (("C-<return>" . my/hs-toggle-node)
           ("C-M-<return>" . my/hs-hide-all))
    :config
    (require 'hideshowvis)

    (defun my/hs-toggle-node ()
        (interactive)
        (if fci-mode
            (progn
                (fci-mode -1)
                (hs-toggle-hiding)
                (fci-mode 1))
            (hs-toggle-hiding)))
    (defun my/hs-hide-all ()
        (interactive)
        (if fci-mode
            (progn
                (fci-mode -1)
                (hs-hide-all)
                (fci-mode 1))
            (hs-hide-all)))
    (defun my/hs-setup ()
        (interactive)
        (hideshowvis-minor-mode t)
        (hideshowvis-symbols)
        (hs-minor-mode t))

    (add-hook 'prog-mode-hook #'my/hs-setup))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; smart M-X -
; autocomplete M-X using ido-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'smex)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; access the orginal M-x with "C-c C-c M-x"
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Auto-complete in source files.
; use the TAB key
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (require 'auto-complete)
;; (require 'auto-complete-c-headers)
;; (setq-default ac-sources '(ac-source-semantic-raw))
;; (require 'auto-complete-config)
;; (ac-config-default)

(require 'expand-region)                ;downloaded via packages
(global-set-key (kbd "C-=") 'er/expand-region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start yasnippet when emacs starts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'yasnippet)
(add-to-list 'yas-snippet-dirs (concat user-emacs-directory "snippets"))
(yas-global-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; autosave and numbered backups
;; from https://www.emacswiki.org/emacs/ForceBackups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; auto save
(defvar my/auto-save-dir (concat user-emacs-directory "auto-saves/"))
(make-directory my/auto-save-dir t)
(setq auto-save-list-file-prefix (concat my/auto-save-dir ".saves-")) ; set prefix for auto-saves
(setq tramp-auto-save-directory my/auto-save-dir)                     ; auto-save tramp files in local directory
(setq auto-save-file-name-transforms
    `(("\\(?:[^/]*/\\)*\\(.*\\)" ,(concat my/auto-save-dir "\\1") t)))
(setq auto-save-timeout 10)
(setq auto-save-interval 0)

;; backup versioning
(setq version-control t     ;; Use version numbers for backups.
      kept-new-versions 10  ;; Number of newest versions to keep.
      kept-old-versions 0   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t)  ;; Copy all files, don't rename them.

(setq vc-make-backup-files t)
(setq backup-directory-alist `(("" . ,(concat user-emacs-directory "backups/per-save"))))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist `(("" . ,(concat user-emacs-directory "backups/per-session"))))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering

    ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))

(add-hook 'before-save-hook  'force-backup-of-buffer)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; iedit-minor-mode.  C-; puts  you into
;; multiple-cursor edit mode for the word at point
;; Here is a function that restricts iedit to the
;; current function scope.
;; With a prefix arg it will search the whole buffer.
;; from: Mastering Emacs book
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(require 'iedit)
(defun iedit-dwim (arg)
  "Start iedit but use \\[narrow-to-defun] to limit its scope.
With a prefix ARG, it will widen the scope to the whole buffer."
  (interactive "P")
  (if arg
    (iedit-mode)
    (save-excursion
      (save-restriction
        (widen)
        ;; this function determines the scope of `iedit-start'.
        (if iedit-mode
          (iedit-done)
          ;; `current-word' can of course be replaced by other
          ;; functions.
          (narrow-to-defun)
          (iedit-start (current-word) (point-min) (point-max)))))))

(global-set-key (kbd "C-;") 'iedit-dwim)


;; ========== multiple cursor mode ====================

(use-package multiple-cursors
    :bind (("C-S-c C-S-c" . mc/edit-lines)
           ("C->" . mc/mark-next-like-this)
           ("C-<" . mc/mark-previous-like-this)
           ("C-c C-<" . mc/mark-all-like-this)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; flycheck settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(javascript-eslint)))

;; eslint was annoying to make it work well
;; I'll stick with gjslint until I need support
;; for React, jsx, or AirBnB mode
(flycheck-add-mode 'javascript-gjslint 'web-mode)
;;(flycheck-add-mode 'javascript-gjslint 'js2-mode)
(flycheck-add-mode 'javascript-gjslint 'js3-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".flycheck")

;;;;;;;;;;;;;
;; whitespace cleanup using ethan-wspace
;; this mode is nice because it only cleans up whitespace
;; on lines that we actually edit, so it doesn't cause spurious
;; whitespace changes in git diff outputs
;;;;;;;;;;;;;
;;(require 'ethan-wspace)
;;(global-ethan-wspace-mode 1)

;; (defun makefile-tabs-are-less-evil ()
;;     "When editing Makefiles, tabs are not errors."
;;     (setq ethan-wspace-errors (remove 'tabs ethan-wspace-errors)))
;; (add-hook 'makefile-mode-hook #'makefile-tabs-are-less-evil)

;;;;;;;;;;;;;
;;;;;;;;;;;;;

(require 'company)
(require 'company-custom)
(setq company-dabbrev-downcase nil)     ; dont downcase inserted autocompletions

;;;;;;;;;;;;;
;;;;;;;;;;;;;
(defun my/one-true-style ()
    "Set my style."
  (c-set-style "bsd")
    (setq-default
        tab-width 2
        c-basic-offset 2
        indent-tabs-mode nil) ; use only spaces for indentation
;;  (require 'auto-complete-c-headers)
;;  (add-to-list 'ac-sources 'ac-source-c-headers)
    )

(add-hook 'c-mode-hook 'my/one-true-style)
(add-hook 'c++-mode-hook 'my/one-true-style)
(add-hook 'objc-mode-hook 'my/one-true-style)
(add-hook 'php-mode-hook 'my/one-true-style)

;; this is better done as a per-project directory variable
;; but I could not get it to work
(add-hook 'c++-mode-hook
    (lambda ()
        (setq flycheck-checker 'c/c++-gcc)
        (setq flycheck-gcc-language-standard "c++11")
        (setq flycheck-clang-language-standard "c++11")))

;; yellow is good on a dark background
(set-face-foreground 'minibuffer-prompt "OrangeRed") ;


;; C/C++ programming
(require 'cc-mode)
(global-font-lock-mode 1)
(c-toggle-hungry-state 1)
(smartparens-global-mode t)
(require 'semantic)

;; shorten the compilation window, and remove it
;; at the end of compilation ONLY if there were no errors.
(setq compilation-window-height 8)
(defun my/compilation-finish-function (buf str)
    "function run at the end of compilation"
    (interactive)
    (when (not (eq major-mode 'grep-mode))
        (if (string-match "exited abnormally" str)
            ;;there were errors
            (message "compilation errors, press C-x ` to visit")
            ;;no errors, make the compilation window go away in 0.5 seconds
            (run-at-time 0.5 nil 'delete-windows-on buf)
            (message "** NO ERRORS **"))))
(setq compilation-finish-functions #'my/compilation-finish-function)

(defun my/build-tab-stop-list (width)
  (let ((num-tab-stops (/ 80 width))
    (counter 1)
    (ls nil))
    (while (<= counter num-tab-stops)
      (setq ls (cons (* width counter) ls))
      (setq counter (1+ counter)))
    (set (make-local-variable 'tab-stop-list) (nreverse ls))))

(defun my/mode-common-hook ()
    (setq tab-width 2)                 ; change this to taste,
    (my/build-tab-stop-list tab-width)
    (setq c-basic-offset tab-width)
    (setq indent-tabs-mode nil)        ; use only SPACES for indentation
    ;;(auto-complete-mode)
    (semantic-mode t)
    (semantic-idle-summary-mode t)
    (semantic-idle-local-symbol-highlight-mode t)
    (semantic-stickyfunc-mode t))
(add-hook 'c-mode-common-hook 'my/mode-common-hook)

(defun my-inhibit-semantic-p ()
    (or (not (equal major-mode 'c-mode))
        (not (equal major-mode 'python-mode))))

(with-eval-after-load 'semantic
      (add-to-list 'semantic-inhibit-functions #'my-inhibit-semantic-p))

;; personal preferences
(c-set-offset 'substatement-open 0)
(c-set-offset 'case-label '+)
(c-set-offset 'arglist-cont-nonempty '+)
(c-set-offset 'arglist-intro '+)
(c-set-offset 'topmost-intro-cont '+)

;; f1 is help
;; f2 is part of ivy-mode
(global-set-key [f2] 'compile)
(global-set-key [f3] 'previous-error)
(global-set-key [f4] 'next-error)
(global-set-key [f6] 'find-tag)
(global-set-key [f7] 'pop-tag-mark)
(auto-compression-mode t)




(setq gdb-many-windows t)
(defun my/gdb-other-frame ()
"Initialize a gdb session in a new frame.
Save window configuration to register 'c' with \\[window-configuration-to-register] c.
Start GDB GUD with \\[execute-extended-command] gdb, then set many window mode with
M-X gdb-many-windows.  Save this debug configuration to register d
with \\[window-configuration-to-register] d.  Now you can switch between coding configuration
and debugging configuration via the registers `c' and `d':
Use \\[jump-to-register] c for coding, and \\[jump-to-register] d for debug."

  (interactive)
  (select-frame (make-frame))
  (call-interactively 'gdb))

;; from http://stackoverflow.com/a/24923325/475482
;; prevent GDB from stealing windows
(defadvice gdb-inferior-filter
    (around gdb-inferior-filter-without-stealing)
  (with-current-buffer (gdb-get-buffer-create 'gdb-inferior-io)
    (comint-output-filter proc string)))
(ad-activate 'gdb-inferior-filter)

(defadvice pop-to-buffer (before cancel-other-window first)
  (ad-set-arg 1 nil))

(ad-activate 'pop-to-buffer)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sticky windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; http://emacs.stackexchange.com/a/2198
(defun toggle-window-dedicated ()
  "Control whether or not Emacs is allowed to display another buffer in current window."
  (interactive)
  (message
   (if (let (window (get-buffer-window (current-buffer)))
         (set-window-dedicated-p window (not (window-dedicated-p window))))
       "%s: This window is now dedicated."
     "%s: This window is not dedicated anymore.")
   (current-buffer)))

(global-set-key [pause] 'toggle-window-dedicated)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Javascript/CSS/SASS/HTML, livereload and in-browser debugging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(require 'js2-mode)
(require 'js2-refactor)
(require 'js3-mode)               ;js3-mode supports node, AMD and CommonJS best
(require 'web-mode)
(require 'css-mode)
(require 'sass-mode)
(require 'jade-mode)

;;(add-hook 'js2-mode-hook #'js2-refactor-mode)
;;(js2r-add-keybindings-with-prefix "C-c C-m")
;; eg. extract function with `C-c C-m ef`.

;; (add-hook 'js2-mode-hook
;;     (lambda ()
;;         (tern-mode t)
;;         (linum-mode t)
;;         ))

(add-hook 'js3-mode-hook
    (lambda ()
        (setq js3-auto-indent-p t)         ; it's nice for commas to right themselves.
        (setq js3-enter-indents-newline t) ; don't need to push tab before typing
        (setq js3-indent-on-enter-key t)   ; fix indenting before moving on
        (tern-mode t)
        (linum-mode t)
        (when (bound-and-true-p my/hs-setup)
            (my/hs-setup))))

(eval-after-load 'tern
    '(progn
         (require 'tern-auto-complete)
         (tern-ac-setup)))

;; Force restart of tern in new projects
;; $ M-x delete-tern-process
(defun delete-tern-process ()
    "Force restart of tern in new project."
    (interactive)
    (delete-process "Tern"))

(add-to-list 'auto-mode-alist `(,(rx ".js" string-end) . js3-mode))
(add-to-list 'auto-mode-alist `(,(rx ".jsx" string-end) . web-mode))
(add-to-list 'auto-mode-alist `(,(rx ".vue" string-end) . web-mode))
(add-to-list 'auto-mode-alist `(,(rx ".htm" string-end) . web-mode))
(add-to-list 'auto-mode-alist `(,(rx ".html" string-end) . web-mode))
(add-to-list 'auto-mode-alist `(,(rx ".phtml" string-end) . web-mode))
(add-to-list 'auto-mode-alist `(,(rx ".php" string-end) . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))

;;(add-hook 'js2-mode-hook 'my/mode-common-hook)
(add-hook 'js3-mode-hook 'my/mode-common-hook)
(add-hook 'web-mode-hook 'my/mode-common-hook)
(add-hook 'css-mode-hook 'my/mode-common-hook)
(add-hook 'sass-mode-hook 'my/mode-common-hook)
(add-hook 'json-mode-hook 'my/mode-common-hook)
(add-hook 'jade-mode-hook
    '(lambda ()
         (progn
             (setq indent-tabs-mode nil)
             (setq tab-width 2))))

(defun my/web-mode-hook ()
  "Hooks for Web mode."
    (setq web-mode-markup-indent-offset 2)
    (setq web-mode-css-indent-offset 2)
    (setq web-mode-code-indent-offset 2)
    (setq web-mode-enable-current-column-highlight t)
)
(add-hook 'web-mode-hook  'my/web-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; from: http://www.howardism.org/Technical/Emacs/eshell-fun.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eshell-here ()
  "Opens up a new shell in the current directory.

\\[eshell-here] opens a new shell in the directory  associated with the
current buffer's file.  The eshell is renamed to match that
directory to make multiple eshell windows easier."
  (interactive)
  (defvar eshell-p)
  (let* ((parent (if (buffer-file-name)
                     (file-name-directory (buffer-file-name))
                   default-directory))
         (height (/ (window-total-height) 3))
         (name   (car (last (split-string parent "/" t))))
     (eshell-p t))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (rename-buffer (concat "*eshell: " name "*"))
    (setq-local eshell-p t)
    ;; (add-hook 'kill-buffer-hook
    ;;            (lamda () (if (or (string-prefix-p "*eshell: " (buffer-name))
    ;;                  (bound-and-true-p eshell-p))
    ;;                  (eshell/x))))

    ;(insert (concat "ls"))
    ;(eshell-send-input)
    ))

(global-set-key (kbd "C-!") 'eshell-here)

;; Exit the shell and close the window just opened for it
(defun eshell/x ()
"Exit the eshell and close the window."
  (goto-char (point-max))
  (eshell-bol)
  (kill-line)
  (insert "exit")
  (eshell-send-input)
  (delete-window))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(require 'tramp)

;;; XEmacs backwards compatibility file
(defmacro GNUEmacs (&rest x)
  (list 'if (string-match "GNU Emacs" (version)) (cons 'progn x)))
(defmacro XEmacs (&rest x)
  (list 'if (string-match "XEmacs" (version)) (cons 'progn x)))
(defmacro Xlaunch (&rest x)
  (list 'if (or (eq window-system 'x)
                (eq window-system 'mswindows))
        (cons 'progn x)))

(XEmacs
 (setq user-init-file
       (expand-file-name "init.el"
       (expand-file-name ".xemacs" "~")))
 (setq custom-file
       (expand-file-name "custom.el"
       (expand-file-name ".xemacs" "~")))

 (load-file user-init-file)
 (load-file custom-file))

(GNUEmacs
  (setq custom-file "~/.emacs.d/site-lisp/custom.el")
  (load custom-file))


;;;;;;;;;;;;;;;;;
;; APPEARANCE
;;;;;;;;;;;;;;;;;
;; (when window-system
;;   (set-frame-size (selected-frame) 140 50)
;;   ;; (toggle-frame-fullscreen) ;; since emacs 2.4.4
;;   (scroll-bar-mode 0)
;;   ;; (tool-bar-mode 0)
;;   ;; (menu-bar-mode 0)
;; )
(setq font-lock-maximum-decoration t)
(setq resize-mini-windows t)
(setq column-number-mode t)
(setq next-line-add-newlines nil)
(setq blink-matching-paren t)
(blink-cursor-mode 1)
(set-cursor-color "#a2676f")
(tool-bar-mode -1)
(tooltip-mode -1)
(scroll-bar-mode 0)
(line-number-mode 1)
(setq default-frame-alist
      '((top . 43)
;;	(left . (/ (- (display-pixel-width) (* 150 (frame-char-width))) 2))
    (left . 370)
        (width . 141) (height . 45)
        ))

;; ========== SMART MODE LINE ===========
(require 'smart-mode-line)
(setq sml/theme 'respectful)
(sml/setup)

;; the fringe is fun to play in

;; (set-fringe-mode
;;  (/ (- (frame-pixel-width)
;;        (* 80 (frame-char-width)))
;;     2))


;; (defun my/resize-margins ()
;;   (let ((margin-size (/ (- (frame-width) 80) 2)))
;;     (set-window-margins nil margin-size margin-size)))

;; (add-hook 'window-configuration-change-hook #'my/resize-margins)
;; ((my/resize-margins)

;; confirm exit with C-X C-C. Doesn't work in daemon mode
(setq confirm-kill-emacs 'yes-or-no-p)
; (add-hook 'kill-emacs-query-functions
;  'custom-prompt-customize-unsaved-options)

;; allow narrow and widen
(put 'narrow-to-region 'disabled nil)
(global-set-key (kbd "C-x n r") 'narrow-to-region)
(global-set-key (kbd "C-x n f") 'narrow-to-defun)

(defun my/insert-date ()
    "inserts the date into the current document"
    (interactive)
    (insert (format-time-string "%x")))

(defun my/insert-time ()
    "inserts the time into the current document"
    (interactive)
    (insert (format-time-string "%X")))

(defun my/insert-iso8601 ()
    "inserts the date and time into the current document in iso8601 format."
    (interactive)
    (insert (format-time-string "%C%y-%m-%dT%H:%M:%SZ")))

(defun my/insert-utc ()
    "inserts the date and time into the current document in utc format."
    (interactive)
    (insert (format-time-string "%C%y-%m-%dT%H:%M:%SZ")))

(defun my/insert-name ()
    "inserts my name and email into the current document."
    (interactive)
    (insert "Brian A. Onn <brian.a.onn@gmail.com>"))

(global-set-key (kbd "C-c i d") 'my/insert-date)
(global-set-key (kbd "C-c i t") 'my/insert-time)
(global-set-key (kbd "C-c i n") 'my/insert-name)
(global-set-key (kbd "C-c i i") 'my/insert-iso8601)
(global-set-key (kbd "C-c i u") 'my/insert-utc)

;; window navigation with control arrows
(global-set-key (kbd "C-<left>") 'windmove-left)
(global-set-key (kbd "C-<right>") 'windmove-right)
(global-set-key (kbd "C-<up>") 'windmove-up)
(global-set-key (kbd "C-<down>") 'windmove-down)

(global-set-key (kbd "C-x g") 'magit-status)

(load "disable-trackpad" t)

(load "server")
(if (not(server-running-p))
    (server-start))

(provide 'emacs)
;;; emacs ends here
