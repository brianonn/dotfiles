;; .emacs -- my initializations
;;; Commentary:
;;; Change Log: 

;;; Code:

(prefer-coding-system 'utf-8)
(when (>= emacs-major-version 24)
  (setq-default buffer-file-coding-system 'utf-8)
  (setq default-buffer-file-coding-system 'utf-8))

;; packages. Access with M-X package-list-packages
(when (>= emacs-major-version 24)
  (require 'package)
  (setq package-archives
	(append package-archives
		(list
     '("marmalade" . "http://marmalade-repo.org/packages/")
     '("melpa" . "http://melpa.org/packages/"))))
    (package-initialize)

  (defvar my-package-list
    '( auto-complete auto-complete-c-headers 
      auto-complete-etags auto-complete-exuberant-ctags
      expand-region
      flycheck
      helm
      iedit
      dart-mode
      json-mode json-reformat json-rpc
      go-mode golint go-scratch
      magit magithub
      markdown-mode
      multiple-cursors mc-extras
      smartparens
      smex
      sass-mode scss-mode
      yasnippet)
    "A list of packages that I want to always have installed.

     This is used by `my-install-packages' whenever I want to
     setup a new emacs deployment on a new host")

  (defun my-install-packages ()
    "Install the packages in the list `my-package-list'.
     This function can be called in .emacs just after `package-initialize'
     or it can be manually called only once when needed for a new deployment"
    (interactive)
    (package-refresh-contents)
    (mapc (lambda (my-package)
       (if (not (package-installed-p my-package))
         (condition-case nil
            (package-install my-package)
          (error nil))))
       my-package-list))
 
 (my-install-packages)		; TODO: create a timestamp file and only call this weekly
)				        ; (when ...


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; org-mode settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

; Add short cut keys for the org-agenda
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-ca" 'org-agenda)

;; =====================================================

;; Interactive Do
(require 'ido)
(ido-mode t)

;; =====================================================


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; smart M-X - 
; autocomplete M-X using ido-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; access the orginal M-x with "C-c C-c M-x"
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Auto-complete in source files. 
; use the TAB key
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'auto-complete)
(require 'auto-complete-c-headers)
(setq-default ac-sources '(ac-source-semantic-raw))
(require 'auto-complete-config)
(ac-config-default)

(require 'expand-region)		;downloaded via packages
(global-set-key (kbd "C-=") 'er/expand-region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start yasnippet when emacs starts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'yasnippet)
(yas-global-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; autosave and numbered backups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq version-control t     ;; Use version numbers for backups.
      kept-new-versions 10  ;; Number of newest versions to keep.
      kept-old-versions 0   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t)  ;; Copy all files, don't rename them.

(setq vc-make-backup-files t)
(setq backup-directory-alist '(("" . "~/.emacs.d/backups/per-save")))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backups/per-session")))
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


;;;;;;;;;;;;;
;;;;;;;;;;;;;

(defun my-one-true-style ()
"Set my style." 
  (c-set-style "bsd")
  (setq-default tab-width 8
		c-basic-offset 4
		indent-tabs-mode nil) ; use only spaces for indentation
  (require 'auto-complete-c-headers)
  (add-to-list 'ac-sources 'ac-source-c-headers))

(add-hook 'c-mode-hook 'my-one-true-style)
(add-hook 'c++-mode-hook 'my-one-true-style)
(add-hook 'objc-mode-hook 'my-one-true-style)
(add-hook 'php-mode-hook 'my-one-true-style)

(add-hook 'after-init-hook #'global-flycheck-mode)

;; yellow is good on a dark background
(set-face-foreground 'minibuffer-prompt "OrangeRed") ;

;; TODO -- it's 2015.. are we still using cc-mode? or is there something better now
(require 'cc-mode)
(global-font-lock-mode 1)
(c-toggle-hungry-state 1)
(smartparens-global-mode t)

;; shorten the compilation window, and remove it 
;; at the end of compilation ONLY if there were no errors.
(setq compilation-window-height 8)
(setq compilation-finish-function
      (lambda (buf str)

        (if (string-match "exited abnormally" str)

            ;;there were errors
            (message "compilation errors, press C-x ` to visit")

          ;;no errors, make the compilation window go away in 0.5 seconds
          (run-at-time 0.5 nil 'delete-windows-on buf)
          (message "** NO ERRORS **"))))

(defun my-build-tab-stop-list (width)
  (let ((num-tab-stops (/ 80 width))
	(counter 1)
	(ls nil))
    (while (<= counter num-tab-stops)
      (setq ls (cons (* width counter) ls))
      (setq counter (1+ counter)))
    (set (make-local-variable 'tab-stop-list) (nreverse ls))))

(defun my-c-mode-common-hook ()
  (setq tab-width 4) ;; change this to taste, 
  (my-build-tab-stop-list tab-width)
  (setq c-basic-offset tab-width)
  (setq indent-tabs-mode nil) ;; force only spaces for indentation
  (auto-complete-mode))
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)


;; personal preferences
(c-set-offset 'substatement-open 0)
(c-set-offset 'case-label '+)
(c-set-offset 'arglist-cont-nonempty '+)
(c-set-offset 'arglist-intro '+)
(c-set-offset 'topmost-intro-cont '+)

(global-set-key [f2] 'compile)
(global-set-key [f3] 'previous-error)
(global-set-key [f4] 'next-error)
(global-set-key [f5] 'find-tag)
(global-set-key [f6] 'pop-tag-mark)
(auto-compression-mode t)

(setq gdb-many-windows t)
(defun my-gdb-other-frame ()
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; from: http://www.howardism.org/Technical/Emacs/eshell-fun.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defun eshell-here ()
  "Opens up a new shell in the current directory.

\\[eshell-here] opens a new shell in the directory  associated with the
current buffer's file.  The eshell is renamed to match that
directory to make multiple eshell windows easier."
  (interactive)
  (let* ((parent (if (buffer-file-name)
                     (file-name-directory (buffer-file-name))
                   default-directory))
         (height (/ (window-total-height) 3))
         (name   (car (last (split-string parent "/" t)))))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (rename-buffer (concat "*eshell: " name "*"))

    ;(insert (concat "ls"))
    ;(eshell-send-input)
    ))

(global-set-key (kbd "C-!") 'eshell-here)

;; Exit the shell and close the window just opened for it
(defun eshell/x ()
"Exit the eshell and close the window."
  (insert "exit")
  (eshell-send-input)
  (delete-window))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(require 'tramp)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(custom-enabled-themes (quote (wombat)))
 '(inhibit-startup-screen t)
 '(org-agenda-files (quote ("~/test.org")))
 '(scroll-bar-mode (quote right))
 '(show-paren-mode t)
 '(transient-mark-mode nil)
 '(blink-cursor-mode t)
 '(blink-cursor-delay 0.5)
 '(cursor-color "#52676f")
 '(org-agenda-files (quote ("~/Dropbox/tmp/time.org")))
 '(org-insert-mode-line-in-empty-file t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:height 130 :family "NanumGothicCoding" :embolden t)))))


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
(setq require-final-newline t)
(setq resize-mini-windows t)
(setq column-number-mode t)
(setq next-line-add-newlines nil)
(setq blink-matching-paren nil)
(blink-cursor-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(scroll-bar-mode 0)

(setq default-frame-alist
      '((top . 43) 
;;	(left . (/ (- (display-pixel-width) (* 150 (frame-char-width))) 2))
	(left . 370)
        (width . 100) (height . 45)
        ))


;; the fringe is fun to play in 

;; (set-fringe-mode
;;  (/ (- (frame-pixel-width)
;;        (* 80 (frame-char-width)))
;;     2))

;; (defun my-resize-margins ()
;;   (let ((margin-size (/ (- (frame-width) 80) 2)))
;;     (set-window-margins nil margin-size margin-size)))

;; (add-hook 'window-configuration-change-hook #'my-resize-margins)
;; ((my-resize-margins)

;; confirm exit with C-X C-C. Doesn't work in daemon mode
(setq confirm-kill-emacs 'yes-or-no-p)

;; allow narrow and widen
(put 'narrow-to-region 'disabled nil)
(global-set-key (kbd "C-x n r") 'narrow-to-region)
(global-set-key (kbd "C-x n f") 'narrow-to-defun)

;(load "server")
;(unless (server-running-p) (server-start))

(provide '.emacs)
;;; .emacs ends here
