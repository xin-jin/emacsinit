;;; fzf.el --- A front-end for fzf.
;;
;; Copyright (C) 2015 by Bailey Ling
;; Author: Bailey Ling
;; URL: https://github.com/bling/fzf.el
;; Package-Version: 20151129.633
;; Filename: fzf.el
;; Description: A front-end for fzf
;; Created: 2015-09-18
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: fzf fuzzy search
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Install:
;;
;; Autoloads will be set up automatically if you use package.el.
;;
;; Usage:
;;
;; M-x fzf
;; M-x fzf-directory
;;
;;; Code:

(defgroup fzf nil
  "Configuration options for fzf.el"
  :group 'convenience)

(defcustom fzf/window-height 15
  "The window height of the fzf buffer"
  :type 'integer
  :group 'fzf)

(defcustom fzf/executable "fzf"
  "The path to the fzf executable."
  :type 'string
  :group 'fzf)

(defcustom fzf/args "-x"
  "Additional arguments to pass into fzf."
  :type 'string
  :group 'fzf)

(defun fzf/after-term-handle-exit (process-name msg)
  (let* ((text (buffer-substring-no-properties (point-min) (point-max)))
         (lines (split-string text "\n" t "\s.*\s"))
         (target (car (last (butlast lines 1))))
         (file (expand-file-name target)))
    (kill-buffer "*fzf*")
    (jump-to-register :fzf-windows)
    (when (file-exists-p file)
      (find-file file)))
  (advice-remove 'term-handle-exit #'fzf/after-term-handle-exit))

(defun fzf/start (directory)
  (let ((default-directory directory))
    (require 'term)
    (window-configuration-to-register :fzf-windows)
    (advice-add 'term-handle-exit :after #'fzf/after-term-handle-exit)
    (let ((buf (get-buffer-create "*fzf*")))
      (split-window-vertically fzf/window-height)
      (if fzf/args
          (apply 'make-term "fzf" fzf/executable nil (split-string fzf/args " "))
        (make-term "fzf" fzf/executable))
      (switch-to-buffer buf)

      ;; disable various settings known to cause artifacts, see #1 for more details
      (setq-local scroll-margin 0)
      (setq-local scroll-conservatively 0)
      (face-remap-add-relative 'mode-line '(:box nil))

      (term-char-mode)
      (setq mode-line-format (format "   FZF  %s" directory)))))

;;;###autoload
(defun fzf ()
  "Starts a fzf session."
  (interactive)
  (if (fboundp #'projectile-project-root)
      (fzf/start (condition-case err
                     (projectile-project-root)
                   (error
                    default-directory)))
    (fzf/start default-directory)))

;;;###autoload
(defun fzf-directory (directory)
  "Starts a fzf session at the specified directory."
  (interactive "D")
  (fzf/start directory))

(provide 'fzf)
;;; fzf.el ends here
