(set-background-color "DarkSlateGray")
(set-foreground-color "Wheat")
(set-default-font "Ubuntu Mono-10")
(set-cursor-color "#da70d6")
(set-mouse-color "#da70d6")
;; Red Hat Linux default .emacs initialization file
;; Adds the ~/.xemacs directory to the load path
(setq load-path (cons (expand-file-name "~/envscripts/.emacs.d/") load-path))
;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.
(global-set-key [delete] 'delete-char)
(global-set-key [kp-delete] 'delete-char)


;;**************************** KEYBINDINGS ********************************

(global-set-key "\M-h" 'help-command)
(global-set-key "\C-h" 'backward-delete-char-untabify)

; Micro Emacs Stuff that I got used to before switching to GNU
(global-set-key "\M-g" 'goto-line)
(global-set-key "\C-x?" 'describe-key-briefly)
(global-set-key "\C-o" 'scroll-down)  ; changed from C-Z because of probs.

;; ************************* VARIABLES **********************************

(setq-default display-time-day-and-date t) ; display day as well as time

(setq-default isearch-case-fold-search nil) ; Set case sensitive searches
(setq-default case-fold-search nil)
(setq-default case-replace nil)         ; Set case sensitive replaces

(setq-default next-line-add-newlines nil) ; Next-line doesn't add new lines

(setq-default auto-save-interval '100) ; auto-save after every 100 actions
(setq-default auto-save-timeout '60) ; auto-save when i'm idle for 60 secs

(setq-default fill-column '78)                  ; wrap around at column 78

(line-number-mode 1)                    ; display line number in status bar

;; ****************************** HOOKS *********************************

(add-hook  'c-mode-hook                       ; set C indent level to 4
      (function (lambda () 
         (setq c-indent-level 4))))

(add-hook 'tex-mode-hook                ; put TeX in outline mode
      (function (lambda () 
          (outline-minor-mode 1)
          (setq outline-regexp "\\\\chap\\|\\\\\\(sub\\)*section"))))

(add-hook 'bibtex-mode-hook             ; bibTeX doesn't need the `` stuff
      (function (lambda () 
          (local-set-key "\"" 'self-insert-command))))

(add-hook  'text-mode-hook                    ; Turn on auto-fill every time
      (function (lambda () (auto-fill-mode 1))))        ; text-mode is run

(font-lock-mode t)
(setq-default font-lock-maximum-decoration t)

;; reset home/end
	    
;; Options Menu Settings
;; =====================
(cond
 ((and (string-match "XEmacs" emacs-version)
       (boundp 'emacs-major-version)
       (or (and
            (= emacs-major-version 19)
            (>= emacs-minor-version 14))
           (= emacs-major-version 20))
       (fboundp 'load-options-file))
  (load-options-file "/home/mbrannig/.xemacs-options")))
;; ============================
;; End of Options Menu Settings
;(load "dotemacs")                       ; moved all of .emacs out so that it
                                        ; could be compiled
(defun up-slightly () (interactive) (scroll-up 5))
(defun down-slightly () (interactive) (scroll-down 5))
(global-set-key [mouse-4] 'down-slightly)
(global-set-key [mouse-5] 'up-slightly)

(defun up-one () (interactive) (scroll-up 1))
(defun down-one () (interactive) (scroll-down 1))
;;(global-set-key [S-mouse-4] 'down-one)
;;(global-set-key [S-mouse-5] 'up-one)


(defun up-a-lot () (interactive) (scroll-up))
(defun down-a-lot () (interactive) (scroll-down))
;;(global-set-key [C-mouse-4] 'down-a-lot)
;;(global-set-key [C-mouse-5] 'up-a-lot)

(setq special-display-buffer-names '("*compilations*" "*VC-Log*"))


(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yaml$" . yaml-mode))

(tool-bar-mode -1)
(menu-bar-mode -1)


