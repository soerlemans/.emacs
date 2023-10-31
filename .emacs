;;; .emacs --- Single file Emacs config that uses EViL binds
;; -*- coding: utf-8; lexical-binding: t -*-

;;; Commentary:
;; This config is a single file that uses use-package for the configuration of packages.
;; Most keybinds are bound under Evil (modal editing).
;; Keys are bound using general (to get a cheat sheet do "SPC h").
;; For this config to work you only need a working package manager.
;; The config will automatically download the necessary packages to work.

;;; Code:
;;- Package manager setup:
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos)) (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl (warn "SSL is not supported")) ; Warn about not using SSL

  ;; Use unstable melpa
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)

  ;; Use gnu elpa if the emacs version > 24
  (when (< emacs-major-version 24)
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))

;; Initialize package manager, with new settings
(package-initialize)

;;- Install use-package:
;; Install use-package if not installed
(eval-when-compile
  (unless (require 'use-package nil 'noerror)
    (package-install 'use-package)))

;; TODO: bind describe-personal-keybindings to something
(use-package use-package
  :ensure t)

;;- Package manager configuration
;; Define some keybinds for package management:
(use-package package
  :ensure t
  :after evil
  :config
  (general-define-key
   :states 'normal
   :prefix "SPC P"
   "l" 'list-packages
   "i" 'package-install
   "d" 'describe-package
   "r" 'package-autoremove))

;; TODO: Do this (https://emacs.stackexchange.com/questions/27926/avoiding-overwriting-global-key-bindings)
;; (define-minor-mode my-keys-mode
;;   "Minor mode for my personal keybindings."
;;   :global t
;;   :keymap (make-sparse-keymap))

;; TODO: Config later
;;(use-package use-package-ensure-system-package
;;  :ensure nil)

;; Emacs asynchronous library
(use-package async
  :ensure t
  :config
  ;; Byte compile Emacs packages asynchronously
  (async-bytecomp-package-mode 1))

;; Automatically update packages
(use-package auto-package-update
  :ensure t
  :config
  (setq auto-package-update-delete-old-versions t)
  (setq auto-package-update-hide-results t)

  (auto-package-update-maybe))

;;; Functions
(defun download-file (t_url)
	"Download a file if it does not exist yet."
	(url-copy-file t_url (file-name-nondirectory t_url) 1)
	)

(defun download-file ()
	"Download a file if it does not exist yet."
	(url-copy-file)
	)

(defun save-to ()
  "Write a copy of the current buffer or region to a file."
  (interactive)
  (let* ((curr (buffer-file-name))
         (new (read-file-name
               "Copy to file: " nil nil nil
               (and curr (file-name-nondirectory curr))))
         (mustbenew (if (and curr (file-equal-p new curr)) 'excl t)))
    (if (use-region-p)
        (write-region (region-beginning) (region-end) new nil nil nil mustbenew)
      (save-restriction
        (widen)
        (write-region (point-min) (point-max) new nil nil nil mustbenew)))))

(defun cursor-indicator ()
  "Change cursor based on evil state."
  ;; TODO: The font and cursor should be set once permanently and not keep being set
  ;; (set-face-attribute 'default nil :family "Iosevka Term" :height 90)
  (when (display-graphic-p)
    (set-mouse-color "spring green")
    (set-cursor-color "spring green"))

  ;; Change modeline to
  ;; (setf mode-line-format ("%e" mode-line-front-space mode-line-mule-info mode-line-client
  ;;              mode-line-modified mode-line-remote mode-line-frame-identification
  ;;              mode-line-buffer-identification "   " mode-line-position evil-mode-line-tag
  ;;              (vc-mode vc-mode)
  ;;              "  " mode-line-modes mode-line-misc-info mode-line-end-spaces))

  ;; TODO: Have the cursor colors change with the evil-state
  (setq cursor-type
        (cond
         ;; (buffer-read-only 'hollow)
         ((eq evil-state 'insert) 'bar)
         ((eq evil-state 'replace) 'hbar)
         (t 'box))))

(defun indicator ()
  "Change modeline based on evil state."
  (cond
   ;; Visual
   ((eq evil-state 'visual)
    (set-face-attribute 'mode-line nil :foreground "#FFFFFF" :background "#669966"))

   ;; Normal
   ((eq evil-state 'normal)
    (set-face-attribute 'mode-line nil :foreground "#FFFFFF" :background "#666699"))

   ;; Insert
   ((eq evil-state 'insert)
    (set-face-attribute 'mode-line nil :foreground "#FFFFFF" :background "#996666"))))

(defun follow-vsplit ()
  "Split frame vertically and open a buffer in the new frame."
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (ivy-switch-buffer))

(defun follow-split ()
  "Split frame horizontally and open a buffer in the new frame."
  (interactive)
  (split-window-horizontally)
  (other-window 1)
  (ivy-switch-buffer))

;; TODO: Add autocomplete DWIM detection
(defun dwim-tab ()
  "Do what I mean tab (format, skip paren or)."
  (interactive)
  (let* ((characters (cl-coerce "(){}[]\"\'" 'list))
         (start-point (point))
         (end-point (+ start-point 2)))
    (dolist (c characters)
      (if (string-match-p (char-to-string c) (buffer-substring-no-properties start-point end-point))
          (forward-char)
        (indent-for-tab-command)))))

;;; Packages
;;- Set Emacs defaults:
(use-package emacs
  :ensure t
  :init
  ;; Emacs:Performance
  ;; This speeds up emacs (the defaults are too low)
  (setq gc-cons-threshold 100000000)       ; Higher garbage threshold = moar speed (10^6)
  (setq read-process-output-max (* 1024 1024)) ; 1Mb

  :after evil
  :hook
  (prog-mode . prettify-symbols-mode)

  (prog-mode . display-fill-column-indicator-mode)
  (prog-mode . (lambda () (setq fill-column 80)))

  (lisp-mode . (lambda () (setq fill-column 100 )))
  (emacs-lisp-mode . (lambda () (setq fill-column 100 )))

  :config
  ;; Emacs:Visual
  ;; Start up to *scratch*
  (setq inhibit-startup-message t)
  (defun display-startup-echo-area-message ()
    "This function is a replacement for the standard Emacs function, it just returns nil."
    nil)

  ;; Disable a few GUI components
  (tool-bar-mode -1)   ; Disable the tool bar with its terrible icons
  (menu-bar-mode -1)   ; Menu bar can be handy sometimes but for now disable it
  (scroll-bar-mode -1) ; Disable the scroll bar
  (tooltip-mode -1)    ; Disable annoying tool-tips

  ;; Them loading
  (when window-system
    (setq custom-safe-themes t)
    ;; (add-hook 'after-init-hook (lambda () (load-theme 'deeper-blue)))
    (add-hook 'after-init-hook (lambda () (load-theme 'tsdh-dark))))

  ;; TODO: move to evil use-package?
  ;; Change inactive modeline colors
  (set-face-attribute
   'mode-line-inactive nil
   :foreground "#333333"
   :background "#A0A0FF")

  ;; Set the mouse and cursor colors
  (set-mouse-color "spring green")
  (set-cursor-color "spring green")

  ;; Change font to Iosevka
  (set-face-attribute 'default nil :family "Iosevka Term" :height 95)

  ;; Cursor settings
  (set-default 'cursor-type 'box)
  (blink-cursor-mode 1)

  ;; Line spacing, can be 0 for code and 1 or 2 for text
  (setq-default line-spacing 0)
  (setq x-underline-at-descent-line t)      ; Underline line at descent position, not baseline position
  (setq-default show-trailing-whitespace t) ; Display trailing whitespace

  ;; Set line numbers
  (global-display-line-numbers-mode)
  (set-face-foreground 'line-number "#668888") ; TODO: Doesnt work needs second eval

  ;; Display relative line numbers
  (setq display-line-numbers-type 'relative)

  ;; Show the boundaries of a buffer (Looks cool but disable for now)
  ;; (setq-default indicate-buffer-boundaries 'left)

  ;; Emacs:Audio
  ;; Disable sound
  (setq visible-bell t)
  (setq ring-bell-function 'ignore)

  ;; Emacs:Behavior
  ;; Prompt settings
  (defalias 'yes-or-no-p 'y-or-n-p)
  (setq confirm-nonexistent-file-or-buffer t)

  ;; Echo my keystrokes inmediately
  (setq echo-keystrokes 0.001)

  ;; Run Dired commands asynchronously
  (dired-async-mode)

  ;; Makes scrolling go one by one
  (setq scroll-conservatively 100)

  ;; Have up to 100 entries in the kill ring
  (setq kill-ring-max 100)

  ;; Which psychopath does not use 2 spaces as tab width
  (setq-default tab-width 2)

  ;; Make paired characters automatically close
  (electric-pair-mode t)

  ;; Emacs:Saves
  ;; Where emacs should keep its saves
  (let ((saves-directory  "~/.emacs.d/saves/"))
    (make-directory saves-directory :parents)  ; Create the directory if it does not exist
    (setq backup-directory-alist `(("." . ,saves-directory))))

  (setq backup-by-copying t)
  (setq delete-old-versions t
        kept-new-versions 5
        kept-old-versions 2
        version-control t))

;; Emacs shell
(use-package eshell
  :ensure t
  :after evil
  :config
  (general-define-key
   :states 'normal
   "SPC RET RET" 'eshell))

;;- Keybinding:
;; Amazing macro for keybinding keychords
(use-package general
  :ensure t
  :config
  ;; Unbind the space key to stop prefix errors
  (general-define-key
   :states '(visual motion)
   "SPC" nil)

  ;;  (general-define-key
  ;;   :states '(normal motion visual)
  ;;   :prefix "SPC"
  ;;   "h" 'help-map)

  (general-define-key
   :states '(normal motion visual)
   ;;:keymaps 'help-map
   "SPC h" 'general-describe-keybindings)
  )

;; Hydras
(use-package hydra
  :ensure t
  :after evil
  :config
  (defhydra hydra-resize-font (:color red)
    "Font resizing hydra."
    ("-" text-scale-decrease "decrease")
    ("+" text-scale-increase "increase")
    ("=" text-scale-increase "increase")
    ("q" (if (bound-and-true-p text-scale-mode)
             (text-scale-mode 0)) "quit"))

  (general-define-key
   :states 'normal
   :prefix "SPC"
   "r f" 'hydra-resize-font/body))

;;- Evil:
;; TODO: Add negative arguments for reverse Upcasing values
;; TODO: Add up, downcase and capilazing keybinds for text
(use-package evil
  :ensure t
  :after general
  :config
  (evil-mode t)

  (add-hook 'post-command-hook 'cursor-indicator)
  (add-hook 'post-command-hook 'indicator)

  ;; Evil:Binds
  (general-define-key
   :states '(normal visual insert)
   "TAB" 'dwim-tab
   ;;"C-k" 'evil-force-normal-state
   "C-k" 'keyboard-quit)

  (general-define-key
   :states '(normal visual)
   ;; :keymaps 'evil-window-map
   :prefix "SPC w "
   ;; Splitting
   "S" 'follow-split
   "V" 'follow-vsplit

   ;; Miscelleanous
   "p" 'evil-window-mru)

  ;; Evil:Window binds
  (general-define-key
   :states '(normal visual)
   :prefix "SPC"
   "w" 'evil-window-map)

  ;; Unbind SPC in visual and evil states
  ;; (general-define-key
  ;;  :states '(visual motion)
  ;;  "SPC" nil)

  ;; Evil:General utilities
  ;; General SPC prefixes
  (general-define-key
   :states '(normal visual)
   :prefix "SPC"
   ;;"C-i" 'insert-file
   "C-f" 'follow-mode))

;; Text objects for code blocks
(use-package evil-indent-plus
  :ensure t
  :after evil
  :config
  (evil-indent-plus-default-bindings))

;; Commenting with counts and motions
(use-package evil-commentary
  :ensure t
  :after evil
  :hook
  (prog-mode . evil-commentary-mode))

;; Increment and decrement numbers
(use-package evil-numbers ;TODO: Maybe remove this package?
  :ensure t
  :after evil
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC n"
   "+" 'evil-numbers/inc-at-pt
   "-" 'evil-numbers/dec-at-pt
   "i +" 'evil-numbers/inc-at-pt-incremental
   "i - " 'evil-numbers/inc-at-pt-incremental))

;; Surround text the vim way
(use-package evil-surround
  :ensure t
  :after (evil)
  :config
  (global-evil-surround-mode))

;; Display information about Evil registers
(use-package evil-owl
  :ensure t
  :after evil
  :config
  ;; Display register information in posframe
  (setq evil-owl-display-method 'posframe
        evil-owl-extra-posframe-args '(:width 50 :height 20 :border-width 1 :border-color "#FFFFFF")
        evil-owl-max-string-length 50)
  (evil-owl-mode t))

;; Multicursors with evil keybinds
(use-package evil-multiedit
  :ensure t
  :after evil
  :config
  (evil-multiedit-default-keybinds)

  (general-define-key
   :states '(normal insert)
	 :keymaps 'evil-multiedit-mode-map
   "M-j" 'evil-multiedit-next
   "M-k" 'evil-multiedit-prev
   "M-h" 'evil-multiedit-beginning-of-line
   "M-l" 'evil-multiedit-end-of-line))

;; Make * work with visual mode
(use-package evil-visualstar
  :ensure t
  :config
  (turn-on-evil-visualstar-mode))

;; Indicates which text is affected by an evil operation
(use-package evil-goggles
  :ensure t
  :config
  (setq evil-goggles-duration 0.050) ; Default is 200 ms make it snappier
  (evil-goggles-mode t))

;;- Mini-buffer
(use-package counsel
  :ensure t)

(use-package swiper
  :ensure t)

;; Ivy needs counsel and swiper to be even more amazing
;; Ivy keybinds need to be configured after Evil
(use-package ivy
  :ensure t
  :after (evil counsel swiper)
  :config
  ;; Ivy:Init
  (ivy-mode t)
  ;; Adds recentf mode and bookmarks to Ivy buffer
  (setq ivy-use-virtual-buffers t)
  (setq enable-recursive-minibuffers t)

  ;; Ivy:Binds
  ;; Ivy:Must have binds
  (general-define-key
   :states '(normal motion visual)
   :prefix "SPC"
   "x" 'counsel-M-x
   "f" 'counsel-find-file
   "b" 'ivy-switch-buffer
   "k" 'ido-kill-buffer)

  ;; Ivy:Retrieve documentation
  (general-define-key
   :states '(normal visual insert)
   :prefix "<f1>"
   "F" 'Info-goto-emacs-command-node
   "b" 'counsel-descbinds
   "f" 'counsel-describe-function
   "k" 'describe-key
   "v" 'counsel-describe-variable
   "l" 'counsel-find-library)

  ;; FIXME: Ivy commands don't bind beyond this point (they don't bind at all)
  ;; Ivy:Special character options
  (general-define-key
   :states '(normal visual insert)
   :prefix "<f2>"
   "RET" 'insert-char           ; TODO: Move to fitting package?
   "S" 'counsel-info-lookup-symbol
   "u" 'counsel-unicode-char
   "j" 'counsel-set-variable)

  ;; Ivy:View management
  (general-define-key
   :states '(normal visual)
   :prefix "SPC v"
   "v" 'ivy-push-view
   "V" 'ivy-pop-view
   "s" 'ivy-switch-view)

  ;; Ivy:Searching
  (general-define-key
   :states '(normal motion visual)
   "?" 'swiper-backward
   "/" 'swiper-isearch)

  ;; Ivy:Meta binds
  (general-define-key
   "M-y" 'counsel-yank-pop)

  ;; Ivy:Minibuffer
  (general-define-key
   :keymaps 'ivy-minibuffer-map
   "M-j" 'ivy-next-line
   "M-k" 'ivy-previous-line))

;; Make Ivy display in a posframe in the center of emacs
(use-package ivy-posframe
  :ensure t
  :after ivy
  :config
  ;; Center ivy posframe at the top and center
  (setq ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-top-center)))

  ;; Make swiper contain less lines to as it fills to much of the screen
  (setq ivy-posframe-height-alist
        '((swiper . 20)
          (t      . 30)))

  (ivy-posframe-mode t))

;; Make Ivy display docstrings
(use-package ivy-rich
  :ensure t
  :after ivy
  :config
  (ivy-rich-mode))

;; Add icons to Ivy
;; TODO: This gives Emacs a major performance hit
(use-package all-the-icons-ivy-rich
  :ensure t
  :disabled
  :if (display-graphic-p)
	:after all-the-icons
  :init (all-the-icons-ivy-rich-mode 1)
  :config
  (setq all-the-icons-ivy-rich-icon-size 1.0))

;;- Mode-line:
;; Have the modeline display the evil-state
(use-package powerline-evil
  :ensure t
  :after evil
  :config
  ;; (powerline-evil-vim-theme)
  )

;; Display position in a buffer using nyan cat
(use-package nyan-mode
  :ensure t
  :config
  (nyan-mode)
  (nyan-start-animation)
  (nyan-stop-music))

;;- Startup Navigation
(use-package dashboard
  :ensure t
  :after all-the-icons
  ;; :hook
  ;; Disable Evil mode in dashboard as it causes conflicting keybinds
  ;; TODO: Maybe override the keys of evil-mode? In dashboard mode?
  ;; FIXME: Turns evil-mode only on for dashboard?
  ;; (dashboard-mode . (lambda () (evil-mode -1)))
  :config
  ;; Dashboard:General look
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner 'logo)

  ;; TODO: Add a widget for desktops
  ;; (defun dashboard-desktops (list-size)
  ;;    "List all desktops and when clicked on open them.")

  ;; (add-to-list '(desktops . dashboard-desktops))
  (setq dashboard-items '((agenda . 5)
                          (recents  . 5)
                          (bookmarks . 5)
                          (projects . 10)
                          ;; (desktops . 5)
                          (registers . 5)))

  ;; Dashboard:Icons
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)

  ;; Dashboard:Miscelleanous
  (setq dashboard-banner-logo-title "Hackerman's Emacs")

  ;; Set dashboard to the initial buffer for emacs-daemon instances
  (setq initial-buffer-choice
        (lambda () (get-buffer "*dashboard*")))
  )

(use-package desktop
  :ensure t
  :after evil
  :config
  ;; Use only one desktop
  (let ((desktop-directory "~/.emacs.d/desktop/"))
    (make-directory desktop-directory :parents)  ; Create the directory if it does not exist
    (setq desktop-path (list desktop-directory)) ; Where to search for Desktop session files
    (setq desktop-dirname desktop-directory))    ; Where to save desktop session files

  (setq desktop-base-file-name "emacs-desktop")

  ;; Conflicts with dashboard package
  ;; (desktop-save-mode 1)

  (general-define-key
   :states '(normal)
   :prefix "SPC d"
   "d" 'desktop-revert
   "s" 'desktop-save-in-desktop-dir
   "r" 'desktop-read))


;;- Project Navigation:
;; TODO: Look if you can hook this program
(use-package projectile
  :ensure t
  :init
  (projectile-mode t)
  :after evil
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC p"
   "s" 'projectile-switch-project
   "f" 'projectile-find-file
   "d" 'projectile-find-file-in-directory
   "b" 'projectile-display-buffer
   "k" 'projectile-kill-buffers
   "g" 'projectile-grep
   )

  (global-set-key (kbd "<f5>") 'projectile-compile-project)
  )

;;- Tab Navigation
(use-package centaur-tabs
  :ensure t
  :if window-system
  :config
  ;; CT:Init
  (centaur-tabs-mode)
  (centaur-tabs-headline-match)

  (centaur-tabs-group-by-projectile-project) ; Projectile intergration

  ;; CT:Visual
  (setq centaur-tabs-height 32)
  (setq centaur-tabs-style "chamfer") ; Tab theme
  (setq centaur-tabs-set-bar 'under) ; Must be set  to properly display-> (setq x-underline-at-descent-line t)

  (setq centaur-tabs-set-icons t)
  ;; (centaur-tabs-change-fonts "arial" 160) ; Set the font

  (setq centaur-tabs-set-close-button nil) ; No close button
  (setq centaur-tabs-show-new-tab-button nil) ; No new tab button

  (setq centaur-tabs-set-modified-marker t) ; Indicate a changed buffer with *

  ;; CT: Behavior
  (setq centaur-tabs-cycle-scope 'tabs) ; Do not change tab group

  ;; CT:Binds
  (general-define-key
   :states 'normal
   :prefix "g"
   "t" 'centaur-tabs-forward
   "T" 'centaur-tabs-backward)
  )

;;- Window Navigation:
;; Adds tag jumping to window selection plus window resizing
(use-package switch-window
  :ensure t
  :after general
  :bind
  ("M-o" . switch-window)

  :config
  ;; Switch:Binds
  (general-define-key
   :states '(normal visual)
   :prefix "SPC"
   "F" 'switch-window-then-find-file)

  ;; Switch:Resizing
  (defhydra hydra-resize-window (:color red)
    "Resize windows."
    ("h" (switch-window-mvborder-left 1))
    ("j" (switch-window-mvborder-down 1))
    ("k" (switch-window-mvborder-up 1))
    ("l" (switch-window-mvborder-right 1)))

  (general-define-key
   :states 'normal
   :prefix "SPC"
   "r w" 'hydra-resize-window/body)

  (general-define-key
   :keymaps 'switch-window-extra-map
   "h" 'switch-window-mvborder-left
   "j" 'switch-window-mvborder-down
   "k" 'switch-window-mvborder-up
   "l" 'switch-window-mvborder-right))

;;- Text Navigation:
;; Avy:
(use-package avy
  :ensure t
  :after evil
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC"
   ";" 'avy-goto-char))

;; Adds tag jumping to ivy
(use-package ivy-avy
  :ensure t
  :after (ivy avy))

;; TODO: Implement tree sitter
;; Treesitter:
;; (use-package avy
;;   :ensure t
;;   )
;;- Key-chord hinting:
;; Shows options for unfinished keychords
(use-package which-key
  :ensure t
  :config
  (setq which-key-idle-delay 1)
  (setq which-key-show-docstrings t)
  (setq which-key-max-description-length nil)
  (setq which-key-side-window-max-height 0.4)

  (which-key-mode t)
  (which-key-setup-side-window-bottom))

(use-package which-key-posframe
  :ensure t
  :after which-key
  (which-key-posframe-mode t)
  (setq which-key-posframe-poshandler 'posframe-poshandler-frame-center))

;;- Visual comprehension:
;; Shows the current indentation level
(use-package indent-guide
  :ensure t
  :hook
  (prog-mode . indent-guide-mode))

(use-package prism
  :ensure t
  :hook
  (emacs-lisp-mode . prism-mode)
  (lisp-mode . prism-mode))

;; (use-package rainbow-delimiters
;;   :ensure t
;;   :hook
;;   (prog-mode . rainbow-delimiters-mode)
;;   :config
;;   (set-face-foreground 'rainbow-delimiters-depth-1-face "#c66")  ; red
;;   (set-face-foreground 'rainbow-delimiters-depth-2-face "#6c6")  ; green
;;   (set-face-foreground 'rainbow-delimiters-depth-3-face "#69f")  ; blue
;;   (set-face-foreground 'rainbow-delimiters-depth-4-face "#cc6")  ; yellow
;;   (set-face-foreground 'rainbow-delimiters-depth-5-face "#6cc")  ; cyan
;;   (set-face-foreground 'rainbow-delimiters-depth-6-face "#c6c")  ; magenta
;;   (set-face-foreground 'rainbow-delimiters-depth-7-face "#ccc")  ; light gray
;;   (set-face-foreground 'rainbow-delimiters-depth-8-face "#999")  ; medium gray
;;   (set-face-foreground 'rainbow-delimiters-depth-9-face "#666")  ; dark gray
;;   )

;; Highlights the matching parens, brackets, etc:
(use-package paren
  :ensure t
  :config
  (setq show-paren-style 'parenthesis)
  (setq show-paren-when-in-periphery nil)
  (setq show-paren-when-point-inside-paren t)
  (setq show-paren-delay 0)
  (show-paren-mode t))

;; Flashes cursor on major viewing changes (scrolling, adding frame, changing frame)
;; Helps with quickly understanding where the cursor is positioned
(use-package beacon
  :ensure t
  :after evil
  :config
  (beacon-mode t))

;;- Documentation:
(use-package helpful
  :ensure t
  :after evil
  ;; TODO: Bind helpful helpers to something handy
  ;; (general-define-key)
  )

;;- Text editing:
(use-package autoinsert
  :ensure t
  :config
  (add-hook 'find-file-hook 'auto-insert)

  (defun autoinsert-yas-expand()
    "Expand an autoinsert template as if it is a yasnippet."
    (yas-expand-snippet (buffer-string) (point-min) (point-max)))

  ;; Always have auto-insert mode on
  (auto-insert-mode 1)

  (setq auto-insert-query nil)
  (setq auto-insert-directory "~/.emacs.d/templates/")

  ;; Auto inserts:
  (define-auto-insert "\\.\\(c\\)\\'" ["default.c" autoinsert-yas-expand])
  (define-auto-insert "\\.\\(cpp\\|cxx|\\)\\'" ["default.cpp" autoinsert-yas-expand])
  (define-auto-insert "\\.\\(h\\)\\'" ["default.h" autoinsert-yas-expand])
  (define-auto-insert "\\.\\(hpp\\|hxx\\)\\'" ["default.hpp" autoinsert-yas-expand])
  (define-auto-insert "\\.\\(lisp\\|ls\\)\\'" ["default.lisp" autoinsert-yas-expand])
  (define-auto-insert "\\.sh\\'" ["default.sh" autoinsert-yas-expand])
  (define-auto-insert "\\.py\\'" ["default.py" autoinsert-yas-expand])
  (define-auto-insert "\\.md\\'" ["default.md" autoinsert-yas-expand])
  )

;; FIXME: Undo tree broken?
;; TODO: Bind undo-tree under SPC u
(use-package undo-tree
  :ensure t
  :config
  ;; Have undo-tree replace the regular Emacs undo system
  (global-undo-tree-mode t)

  ;; Prevent undo-tree from cluttering my drive with *.~undo-tree~ files
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo"))))

;;- Spelling:
;; Spelling checking
(use-package flyspell
  :ensure t
  :hook
  (text-mode . flyspell-mode)
  (prog-mode . flyspell-prog-mode))

;; Spelling correction
(use-package ispell
  :ensure t
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "C-c"
   "c" 'ispell-change-dictionary
   "b" 'ispell-buffer
   "w" 'ispell-word
   "r" 'ispell-region)) ; TODO: check this out

;;- Formatting:
;; Use formatters
(use-package format-all
  :ensure t
  :hook
  (prog-mode . format-all-ensure-formatter)
  :config
  (general-define-key
   :states 'normal
   :prefix "SPC"
   "TAB" 'format-all-buffer
   )
  ;; TODO: Set format-all-formatters to give command line args to certain formatters
  )

;;- Syntax checking:
(use-package flycheck
  :ensure t
  :init
  (global-flycheck-mode)
  :config
  ;; Flycheck:binds
  (general-define-key
   :states 'normal
   :prefix "SPC !"
   "l" 'flycheck-list-errors
   ))

;;- Auto-complete:
(use-package company
  :ensure t
  :after evil
  :init (global-company-mode)
  :config
  (setq company-idle-delay 0.1) ; 0.1 second delay on autocomplete
  (setq company-minimum-prefix-length 2)
  (add-to-list 'company-backends 'company-elisp)

  ;; Start completion whenever you want
  (general-define-key
   :states '(insert)
   "M-RET" 'company-complete-common)

  (general-define-key
   :keymaps 'company-active-map
   "M-j" 'company-select-next
   "M-k" 'company-select-previous))

;; Prettify company
(use-package company-box
  :ensure t
  :hook (company-mode . company-box-mode))

(use-package company-shell
  :ensure t
  :after company
  :config
  (add-to-list 'company-backends '(company-shell company-shell-env)))

(use-package company-math
  :ensure t
  :after company
  :config
  ;; Global activation of the unicode symbol completion.
  (add-to-list 'company-backends 'company-math-symbols-unicode))

;;- Language server protocol:
(use-package eglot
  :ensure t
  :after (evil company)
  :hook
  ;; (prog-mode . eglot-ensure)
  (c-mode . eglot-ensure) ; Clangd
  (c++-mode . eglot-ensure) ; Clangd
  (python-mode . eglot-ensure) ; pyls
  (go-mode . eglot-ensure) ; gopls
  (sh-mode . eglot-ensure) ; bash-ls
  (js-mode . eglot-ensure) ; typescript-language-server
  (css-mode . eglot-ensure) ; cssls
  (tex-mode . eglot-ensure) ; digestif
  (latex-mode . eglot-ensure) ; digestif
  (LaTeX-mode . eglot-ensure) ; digestif
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC e"
   "e" 'eldoc
   "r" 'eglot-rename
   "f d" 'xref-find-definitions
   "f r" 'xref-find-references
   "c a" 'eglot-code-actions
   )
  )

;;- Snippets:
(use-package yasnippet
  :ensure t
  :after evil
  :hook
  ;; Hook Yasnippet minor mode into all programming modes
  (prog-mode . yas-minor-mode)
  (tex-mode . yas-minor-mode)
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC s"
   "n" 'yas-new-snippet
   "f" 'yas-visit-snippet-file))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

(use-package yasnippet-classic-snippets
  :ensure t
  :after yasnippet)

(use-package common-lisp-snippets
  :ensure t
  :after yasnippet)

(use-package ivy-yasnippet
  :ensure t
  :after (yasnippet ivy)
  :config
  (general-define-key
   :states '(normal visual)
   :prefix "SPC s"
   "s" 'ivy-yasnippet))

;;- Common Lisp:
(use-package slime
  :ensure t
  :config
  ;; Set the LISP REPL
  (setq inferior-lisp-program "sbcl")
  (slime-setup '(slime-fancy slime-company))

  (general-define-key
   :states '(normal visual)
   :prefix "SPC RET"
   "s" 'slime)

  (general-define-key
   :states '(normal visual)
   :prefix "C-h"
   "C-l" 'slime-documentation-lookup))

;; TODO: Find a place for this
;; TODO: Launch Slime when opening .lisp files
(add-to-list 'auto-mode-alist '("\\.lisp\\'" . common-lisp-mode))

;; Lisp development improvements:
(use-package slime-company
  :ensure t
  :after (slime company)
  :config
  (setq slime-company-completion 'fuzzy
        slime-company-after-completion 'slime-company-just-one-space)

  (add-to-list 'company-backends 'company-slime)
  )

;;- LaTeX:
;; Enhanced Tex en Latex modes (replaces the originals automatically)
(use-package auctex
  :ensure t
  :config
  ;; Enables document parsing
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)

  ;; Query for master LaTeX filE
  (setq-default TeX-master nil))

;;- Misc. Programming language modes:
;; Completion for python
(use-package elpy
  :ensure t
  ;; There are also other dependencies
  :after (company yasnippet)
  :defer t
  :init
  ;; (advice-add 'python-mode :before 'elpy-enable)
  )

;; Go mode
(use-package go-mode
  :ensure t)

;;- Misc. Programming modes:
;; Web development mode
(use-package web-mode
  :ensure t
  :mode ("\\.php\\'" "\\.ts\\'" "\\.js\\'" "\\.html?\\'" "\\.css?\\'")
  )

;; Highlight doxygen mode
(use-package highlight-doxygen
  :ensure t
	:hook
	(prog-mode . highlight-doxygen-mode))

;; Dockerfile mode
(use-package dockerfile-mode
  :ensure t)

;; YAML mode
(use-package yaml-mode
  :ensure t)

;; YAML mode
(use-package plantuml-mode
  :ensure t
  :hook
  ;; Electrict indent and plantuml do not play nice
  (plantum-mode . (lambda () (electric-indent-mode -1)))
  :config
  (setq-default plantuml-indent-level 2))

;; Markdown mode
(use-package markdown-mode
  :ensure t)

;;- Font glyphs:
(use-package all-the-icons
  :ensure t
  :if (display-graphic-p)
	:config
	(unless (file-exists-p "~/.local/share/fonts/all-the-icons.ttf")
		(all-the-icons-install-fonts t)))

;;- Version control:
;; Magit for handling git repositories:
(use-package magit
  :ensure t
  :defer 5)

(use-package ediff
  :ensure t
  :after ediff
  :config
  ;; Dont create a floating window, just open a frame
  (setq ediff-window-setup-function 'ediff-setup-windows-plain)

  (general-define-key
   :states '(normal)
   :prefix "SPC m"
   "e" 'magit-ediff
   "d" 'magit-ediff-dwim))

;; Display git diffs on branch:
(use-package git-gutter+
  :ensure t
  :defer 5
  :config
  (global-git-gutter+-mode t))

;;- OS interaction:
;; Change user to edit a file
(use-package sudo-edit
  :ensure t
  :after evil
  :config
  (general-define-key
   :states 'normal
   :prefix "SPC"
   "C-r" 'sudo-edit))

;; Syncs up the system clip board with the kill-ring
(use-package xclip
  :ensure t
  :config
  (xclip-mode t))

;;; End of Config
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
	 [default default default italic underline success warning error])
 '(ansi-color-names-vector
	 ["#2d3743" "#ff4242" "#74af68" "#dbdb95" "#34cae2" "#008b8b" "#00ede1" "#e1e1e0"])
 '(custom-enabled-themes '(manoj-dark))
 '(hl-todo-keyword-faces
	 '(("TODO" . "#E5E221")
		 ("NEXT" . "#E5E221")
		 ("THEM" . "#57ACA0")
		 ("PROG" . "#0756A1")
		 ("OKAY" . "#0756A1")
		 ("DONT" . "#C2BC31")
		 ("FAIL" . "#C2BC31")
		 ("DONE" . "#fbfc37")
		 ("NOTE" . "#E5E221")
		 ("KLUDGE" . "#E5E221")
		 ("HACK" . "#E5E221")
		 ("TEMP" . "#E5E221")
		 ("FIXME" . "#E5E221")
		 ("XXX+" . "#E5E221")
		 ("\\?\\?\\?+" . "#E5E221")))
 '(package-selected-packages
	 '(typescript-mode highlight-doxygen prism vdiff plantuml-mode toml-mode flycheck-clang-tidy rust-mode cmake-mode bison-mode vertico helpful yasnippet-snippets yasnippet-classic-snippets yaml-mode xclip which-key-posframe web-mode use-package undo-tree treemacs-projectile treemacs-all-the-icons switch-window sudo-edit smart-tabs-mode slime-company sass-mode rainbow-delimiters powerline-evil perspective nyan-mode melancholy-theme markdown-preview-mode magit lsp-ui lsp-treemacs lsp-ivy ivy-yasnippet ivy-rich ivy-posframe ivy-avy indent-guide go-mode git-gutter+ general format-all flycheck flatland-theme fira-code-mode evil-visualstar evil-surround evil-owl evil-numbers evil-multiedit evil-indent-plus evil-goggles evil-commentary elpy elcord eglot dockerfile-mode dashboard counsel company-shell company-math company-box company-auctex common-lisp-snippets chess centaur-tabs beacon auto-package-update async arduino-mode))
 '(send-mail-function 'mailclient-send-it)
 '(slime-company-display-arglist t)
 '(tags-apropos-additional-actions '(("Common Lisp" clhs-doc clhs-symbols))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
