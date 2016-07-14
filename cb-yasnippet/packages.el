;;; packages.el --- cb-yasnippet Layer packages File for Spacemacs
;;; Commentary:
;;; Code:

(require 'dash)
(require 'f)
(require 's)
(require 'use-package)

(autoload 'evil-insert-state "evil-states")

(defconst cb-yasnippet-packages
  '(yasnippet
    smartparens))

(defvar cb-yasnippet/main-snippets-dir
  (f-join user-layers-directory "cb-yasnippet/snippets"))

(defun cb-yasnippet/post-init-yasnippet ()
  (use-package yasnippet
    :defer t
    :init
    (add-hook 'prog-mode-hook (lambda () (require 'yasnippet)))
    :config
    (progn
      (spacemacs/declare-prefix "y" "yasnippet")
      (spacemacs/set-leader-keys "yf" #'yas-visit-snippet-file)
      (spacemacs/set-leader-keys "ye" #'yas-expand)
      (spacemacs/set-leader-keys "yn" #'yas-new-snippet)
      (spacemacs/set-leader-keys "yy" #'yas-insert-snippet)
      (spacemacs/set-leader-keys "yr" #'cb-yas/reload-all)

      (setq yas-snippet-dirs cb-yasnippet/yas-dirs)

      (spacemacs|diminish yas-minor-mode " ⓨ" " y")

      (cb-yas/register-snippets-dir cb-yasnippet/main-snippets-dir)

      (add-hook 'yas-minor-mode-hook #'cb-yas/sync-with-yasnippet)
      (setq yas-prompt-functions '(yas-ido-prompt))
      (setq yas-wrap-around-region t)
      (setq yas-verbosity 0)
      (setq yas-triggers-in-field nil)

      (core/remap-face 'yas-field-highlight-face 'cb-faces-bg-hl-template)

      (add-hook 'snippet-mode-hook (lambda () (setq-local require-final-newline nil)))

      (bind-key (kbd "TAB") #'yas-expand prog-mode-map)
      (evil-define-key 'insert yas-minor-mode-map (kbd "TAB") #'yas-expand)
      (bind-key "<backspace>" 'yas/backspace yas-keymap)
      (evil-define-key 'insert yas-keymap (kbd "SPC") #'yas/space)

      ;; Advise editing commands.
      ;;
      ;; Pressing SPC in an unmodified field will clear it and switch to the next.
      ;;
      ;; Pressing S-TAB to go to last field will place point at the end of the field.

      (defun cb-yasnippet/goto-field-end (&rest _)
        (yas/maybe-goto-field-end)
        (when (and (boundp 'evil-mode) evil-mode)
          (evil-insert-state)))

      (advice-add 'yas-next-field :before #'yas/clear-blank-field)
      (advice-add 'yas-prev-field :before #'yas/clear-blank-field)
      (advice-add 'yas-next-field :after #'cb-yasnippet/goto-field-end)
      (advice-add 'yas-prev-field :after #'cb-yasnippet/goto-field-end)

      (yas/reload-all)
      (yas-global-mode +1)

      ;; HACK: Override weird Spacemacs behaviour that disables smartparens in
      ;; yasnippet.
      (with-eval-after-load 'smartparens
        (add-hook 'yas-before-expand-snippet-hook #'turn-on-smartparens-strict-mode t)
        (add-hook 'yas-after-exit-snippet-hook #'turn-on-smartparens-strict-mode t)))))

(defun cb-yasnippet/post-init-smartparens ()
  (use-package smartparens
    :config
    (progn
      ;; HACK: Work around Spacemacs issue with smartparens strict mode.

      (defun cb-yasnippet/disable-smartparens-strict-mode ()
        (smartparens-strict-mode -1))

      (defun cb-yasnippet/restore-smartparens-strict-mode ()
        (smartparens-strict-mode +1))

      (add-hook 'yas-before-expand-snippet-hook #'cb-yasnippet/disable-smartparens-strict-mode)
      (add-hook 'yas-after-exit-snippet-hook #'cb-yasnippet/restore-smartparens-strict-mode))))

;;; packages.el ends here
