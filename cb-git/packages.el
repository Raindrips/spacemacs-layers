;;; packages.el --- cb-git Layer packages File for Spacemacs
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package nil t))

(defconst cb-git-packages
  '(magit
    git-commit
    vc
    git-auto-commit-mode
    (git-commit-jira-prefix :location local)
    (magit-browse-repo :location local)))

(defun cb-git/init-vc ()
  (setq vc-follow-symlinks t))

(defun cb-git/pre-init-magit ()
  (setenv "GIT_EDITOR" "emacsclient"))

(defun cb-git/post-init-magit ()
  (use-package magit
    :defer t
    :config
    (progn
      (core/remap-face 'magit-section-highlight 'cb-faces-bg-hl-ok)
      (core/remap-face 'magit-diff-context-highlight 'cb-faces-bg-hl-ok)

      (define-key magit-mode-map (kbd "SPC") nil)
      (define-key magit-status-mode-map (kbd "S-SPC") #'helm-M-x))))

(defun cb-git/post-init-git-commit ()
  (use-package git-commit
    :after magit
    :config
    (progn
      ;; Remove broken Spacemacs customisation
      (remove-hook 'git-commit-mode-hook 'fci-mode)
      (evil-set-initial-state 'git-commit-mode 'insert))))

(defun cb-git/init-git-auto-commit-mode ()
  (use-package git-auto-commit-mode
    :diminish git-auto-commit-mode
    :init
    (add-to-list 'safe-local-variable-values '(gac-automatically-push-p . t))))

(defun cb-git/init-git-commit-jira-prefix ()
  (use-package git-commit-jira-prefix
    :after git-commit
    :commands git-commit-jira-prefix-init
    :config (git-commit-jira-prefix-init)))

(defun cb-git/init-magit-browse-repo ()
  (use-package magit-browse-repo
    :commands (magit-browse-repo)
    :after (magit)
    :config
    (define-key magit-status-mode-map (kbd "&") #'magit-browse-repo)))
