;;; helm-haskell-import.el --- haskell utilities with helm

;; Copyright (C) 2012 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-helm-haskell-import
;; Version: 0.01
;; Package-Requires: ((helm "1.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Port of Vim's `unite-haskellimport'
;;   - https://github.com/ujihisa/unite-haskellimport

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'helm)

(defgroup helm-haskell-import nil
  "hoogle with helm interface"
  :group 'helm)

(defun helm-c-haskell-imp-init ()
  (let ((pattern (read-string "Pattern: ")))
    (with-current-buffer (helm-candidate-buffer 'global)
      (let* ((cmd (format "hoogle %s" pattern))
             (ret (call-process "hoogle" nil t nil pattern)))
        (unless (= ret 0)
          (error "Failed helm-c-haskell-imp-init"))))))

(defun helm-c-haskell-split-candidate (candidate)
  (let ((regexp "^\\([^ ]+\\) \\([^ ]+\\) :: \\(.+\\)$"))
    (when (string-match regexp candidate)
      (list
       :package (match-string  1 candidate)
       :function (match-string 2 candidate)
       :type (match-string 3 candidate)))))

(defun helm-c-haskell-search-insert-point ()
  (let ((regexp "^\\s-*import\\s-+"))
    (save-excursion
      (goto-char (line-end-position))
      (if (re-search-backward regexp nil t)
          (progn
            (forward-line 1)
            (point))
        (point-min)))))

(defun helm-c-haskell-imp-construct-inserted (modules)
  (mapconcat (lambda (m)
               (format "import %s\n" (plist-get m :package)))
               modules ""))

(defun helm-c-haskell-imp-collect-module-infos ()
  (loop for c in (helm-marked-candidates)
        when (helm-c-haskell-split-candidate c)
        collect it))

(defun helm-c-haskell-imp-check-imported (package)
  (let ((regexp (format "import\\s-+%s" package)))
    (save-excursion
      (goto-char (line-end-position))
      (re-search-backward regexp nil t))))

(defun helm-c-haskell-imp-filter-not-imported (module-infos)
  (loop for m in module-infos
        for package = (plist-get m :package)
        unless (helm-c-haskell-imp-check-imported package)
        collect m))

(defun helm-c-haskell-imp-insert-module (candidate)
  (let* ((module-infos (helm-c-haskell-imp-collect-module-infos))
         (not-importeds (helm-c-haskell-imp-filter-not-imported module-infos))
         (inserted-point (helm-c-haskell-search-insert-point)))
    (save-excursion
      (goto-char inserted-point)
      (insert (helm-c-haskell-imp-construct-inserted not-importeds)))))

(defvar helm-c-haskell-imp-source
  '((name . "helm haskell import")
    (init . helm-c-haskell-imp-init)
    (candidates-in-buffer)
    (action . (("Insert Module" . helm-c-haskell-imp-insert-module)))
    (volatile)
    (candidate-number-limit . 9999)))

;;;###autoload
(defun helm-haskell-import ()
  (interactive)
  (let ((buf (get-buffer-create "*helm haskell import*")))
    (helm :sources '(helm-c-haskell-imp-source) :buffer buf)))

(provide 'helm-haskell-import)

;;; helm-haskell-import.el ends here
