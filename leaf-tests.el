;;; leaf-tests.el ---                                -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; URL: https://github.com/conao3/leaf.el

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

;;

;;; Code:

(require 'leaf)
(require 'cort-test)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  test settings
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  support legacy Emacs
;;

(when (not (fboundp 'autoload-do-load))
  (defun autoload-do-load (fundef &optional funname macro-only)
    (if (or (not (consp fundef)) (not (eql 'autoload (car fundef))))
        fundef
      (let ((kind (nth 4 fundef)))
        (if (and (eql macro-only 'macro)
                 (not (or (eql kind t)
                          (eql kind 'macro))))
            fundef)
        (if purify-flag
            (error "Attempt to autoload %s while preparing to dump" (symbol-name funnname)))
        (unwind-protect
            (let ((ignore-errors (if (or (eql kind t) (eql kind 'macro)) nil macro_only)))
              (load (cadr fundef) ignore-errors t nil t))
          ;; FIXME: revert partially performed defuns
          ())
        (if (or (not funname) ignore-errors)
            nil
          (let ((fun (indirect-function funname, nil)))
            (if (equal fun fundef)
                (error "Autoloading file %s failed to define function %s"
                       (caar load-history)
                       (symbol-name funname))
              fun)))))))

(when (not (fboundp 'macroexpand-1))
  (defun macroexpand-1 (form &optional environment)
    "Perform (at most) one step of macroexpansion."
    (cond
     ((consp form)
      (let* ((head (car form))
             (env-expander (assq head environment)))
        (if env-expander
            (if (cdr env-expander)
                (apply (cdr env-expander) (cdr form))
              form)
          (if (not (and (symbolp head) (fboundp head)))
              form
            (let ((def (autoload-do-load (symbol-function head) head 'macro)))
              (cond
               ;; Follow alias, but only for macros, otherwise we may end up
               ;; skipping an important compiler-macro (e.g. cl--block-wrapper).
               ((and (symbolp def) (macrop def)) (cons def (cdr form)))
               ((not (consp def)) form)
               (t
                (if (eq 'macro (car def))
                    (apply (cdr def) (cdr form))
                  form))))))))
     (t form))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  support macros for test definition
;;

(defmacro cort-deftest-with-macroexpand (name form)
  "Return `cort-deftest' compare by `equal' for NAME, FORM.

Example
  (p (cort-deftest-with-equal leaf/disabled
       '((asdf asdf)
         (uiop uiop))))
   => (cort-deftest leaf/disabled
        '((:equal asdf asdf)
          (:equal uiop uiop)))
"
  (declare (indent 1))
  `(cort-deftest ,name
     ',(mapcar (lambda (elm)
                 `(:equal
                   ',(cadr elm)
                   (macroexpand-1 ',(car elm))))
               (cadr form))))

(defmacro match-expansion-let (letform form expect)
  (declare (indent 1))
  `(:equal (let ,letform (macroexpand-1 ',form)) ,expect))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  test definition
;;

(cort-deftest-with-macroexpand leaf/disabled
  '(((leaf leaf :disabled t       :config (leaf-init))
     nil)
    ((leaf leaf :disabled nil     :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled t t     :config (leaf-init))
     nil)
    ((leaf leaf :disabled t nil   :config (leaf-init))
     nil)
    ((leaf leaf :disabled nil t   :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil nil :config (leaf-init))
     (progn
        (leaf-init)))

    ((leaf leaf :disabled t :disabled t       :config (leaf-init))
     nil)
    ((leaf leaf :disabled t :disabled nil     :config (leaf-init))
     nil)
    ((leaf leaf :disabled t :disabled t t     :config (leaf-init))
     nil)
    ((leaf leaf :disabled t :disabled t nil   :config (leaf-init))
     nil)
    ((leaf leaf :disabled t :disabled nil t   :config (leaf-init))
     nil)
    ((leaf leaf :disabled t :disabled nil nil :config (leaf-init))
     nil)

    ((leaf leaf :disabled nil :disabled t       :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil     :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled t t     :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled t nil   :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil t   :config (leaf-init))
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil nil :config (leaf-init))
     (progn
        (leaf-init)))

    ((leaf leaf :disabled t :disabled t       :config (leaf-init) :disabled t)
     nil)
    ((leaf leaf :disabled t :disabled nil     :config (leaf-init) :disabled nil)
     nil)
    ((leaf leaf :disabled t :disabled t t     :config (leaf-init) :disabled t t)
     nil)
    ((leaf leaf :disabled t :disabled t nil   :config (leaf-init) :disabled t nil)
     nil)
    ((leaf leaf :disabled t :disabled nil t   :config (leaf-init) :disabled nil t)
     nil)
    ((leaf leaf :disabled t :disabled nil nil :config (leaf-init) :disabled nil nil)
     nil)

    ((leaf leaf :disabled nil :disabled t       :config (leaf-init) :disabled t)
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil     :config (leaf-init) :disabled nil)
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled t t     :config (leaf-init) :disabled t t)
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled t nil   :config (leaf-init) :disabled t nil)
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil t   :config (leaf-init) :disabled nil t)
     (progn
        (leaf-init)))
    ((leaf leaf :disabled nil :disabled nil nil :config (leaf-init) :disabled nil nil)
     (progn
        (leaf-init)))))

;; This test failed on Emacs-22 and Emacs-23
;; (cort-deftest-with-macroexpand leaf/ensure
;;   '(((leaf leaf :ensure t :config (leaf-init))
;;      (progn
;;        (unless
;;            (package-installed-p 'leaf)
;;          (condition-case-unless-debug err
;;              (if
;;                  (assoc 'leaf package-archive-contents)
;;                  (package-install 'leaf)
;;                (package-refresh-contents)
;;                (package-install 'leaf))
;;            (error
;;             (display-warning 'leaf
;;                              (format "Failed to install %s: %s" 'leaf
;;                                      (error-message-string err))
;;                              :error))))
;;        (leaf-init)))))

(cort-deftest-with-macroexpand leaf/doc
  '(((leaf leaf
       :doc "Symplify init.el configuration"
       :config (leaf-init))
     (progn
       (leaf-init)))

    ((leaf leaf
       :file "~/.emacs.d/elpa/leaf.el/leaf.el"
       :config (leaf-init))
     (progn
       (leaf-init)))

    ((leaf leaf
       :url "https://github.com/conao3/leaf.el"
       :config (leaf-init))
     (progn
       (leaf-init)))

    ((leaf leaf
       :doc "Symplify init.el configuration"
       :file "~/.emacs.d/elpa/leaf.el/leaf.el"
       :url "https://github.com/conao3/leaf.el"
       :config (leaf-init))
     (progn
       (leaf-init)))

    ((leaf leaf
       :doc "Symplify init.el configuration"
       "
(leaf leaf
  :doc \"Symplify init.el configuration\"
  :config (leaf-init))
 => (progn
      (leaf-init))"
       "
(leaf leaf
  :disabled nil
  :config (leaf-init))
 => (progn
      (leaf-init))"
       :file "~/.emacs.d/elpa/leaf.el/leaf.el"
       :url "https://github.com/conao3/leaf.el"
       :config (leaf-init))
     (progn
       (leaf-init)))))

(cort-deftest-with-macroexpand leaf/load-path
  '(((leaf leaf
       :load-path "~/.emacs.d/elpa-archive/leaf.el/"
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (require 'leaf)
       (leaf-init)))

    ((leaf leaf
       :load-path
       "~/.emacs.d/elpa-archive/leaf.el/"
       "~/.emacs.d/elpa-archive/leaf-browser.el/"
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf-browser.el/")
       (require 'leaf)
       (leaf-init)))

    ((leaf leaf
       :load-path ("~/.emacs.d/elpa-archive/leaf.el/"
                   "~/.emacs.d/elpa-archive/leaf-browser.el/")
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf-browser.el/")
       (require 'leaf)
       (leaf-init)))

    ((leaf leaf
       :load-path ("~/.emacs.d/elpa-archive/leaf.el/"
                   ("~/.emacs.d/elpa-archive/leaf.el/"
                    "~/.emacs.d/elpa-archive/leaf-browser.el/"))
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf-browser.el/")
       (require 'leaf)
       (leaf-init)))

    ((leaf leaf
       :load-path ("~/.emacs.d/elpa-archive/leaf.el/"
                   ("~/.emacs.d/elpa-archive/leaf.el/"
                    ("~/.emacs.d/elpa-archive/leaf.el/"
                     ("~/.emacs.d/elpa-archive/leaf.el/"
                      ("~/.emacs.d/elpa-archive/leaf.el/")))))
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (require 'leaf)
       (leaf-init)))

    ((leaf leaf
       :load-path ("~/.emacs.d/elpa-archive/leaf.el/")
       :load-path `(,(mapcar (lambda (elm)
                               (concat "~/.emacs.d/elpa-archive/" elm "/"))
                             '("leaf.el" "leaf-broser.el" "orglyth.el")))
       :require t
       :config (leaf-init))
     (progn
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf.el/")
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/leaf-broser.el/")
       (add-to-list 'load-path "~/.emacs.d/elpa-archive/orglyth.el/")
       (require 'leaf)
       (leaf-init)))))

(cort-deftest-with-macroexpand leaf/defun
  '(((leaf leaf
       :defun leaf leaf-normalize-plist leaf-merge-dupkey-values-plist)
     (progn
       (declare-function leaf "leaf")
       (declare-function leaf-normalize-plist "leaf")
       (declare-function leaf-merge-dupkey-values-plist "leaf")))

    ((leaf leaf
       :defun (leaf leaf-normalize-plist leaf-merge-dupkey-values-plist))
     (progn
       (declare-function leaf "leaf")
       (declare-function leaf-normalize-plist "leaf")
       (declare-function leaf-merge-dupkey-values-plist "leaf")))

    ((leaf leaf
       :defun (leaf
                (leaf-normalize-plist
                 (leaf-merge-dupkey-values-plist))))
     (progn
       (declare-function leaf "leaf")
       (declare-function leaf-normalize-plist "leaf")
       (declare-function leaf-merge-dupkey-values-plist "leaf")))

    ((leaf leaf
       :defun ((lbrowser-open lbrowser-close) . leaf-browser))
     (progn
       (declare-function lbrowser-open "leaf-browser")
       (declare-function lbrowser-close "leaf-browser")))

    ((leaf leaf
       :defun (lbrowser-open lbrowser-close . leaf-browser))
     (progn
       (declare-function lbrowser-open "leaf-browser")
       (declare-function lbrowser-close "leaf-browser")))

    ((leaf leaf
       :defun ((lbrowser-open (lbrowser-close) . leaf) . leaf-browser))
     (progn
       (declare-function lbrowser-open "leaf")
       (declare-function lbrowser-close "leaf")))

    ((leaf leaf
       :defun ((lbrowser-open (lbrowser-close) . leaf) leaf-asdf . leaf-browser))
     (progn
       (declare-function lbrowser-open "leaf")
       (declare-function lbrowser-close "leaf")
       (declare-function leaf-asdf "leaf-browser")))))

(cort-deftest-with-macroexpand leaf/defvar
  '(((leaf leaf
       :defvar leaf leaf-normalize-plist leaf-merge-dupkey-values-plist)
     (progn
       (defvar leaf)
       (defvar leaf-normalize-plist)
       (defvar leaf-merge-dupkey-values-plist)))

    ((leaf leaf
       :defvar (leaf leaf-normalize-plist leaf-merge-dupkey-values-plist))
     (progn
       (defvar leaf)
       (defvar leaf-normalize-plist)
       (defvar leaf-merge-dupkey-values-plist)))

    ((leaf leaf
       :defvar (leaf
                (leaf-normalize-plist
                 (leaf-merge-dupkey-values-plist))))
     (progn
       (defvar leaf)
       (defvar leaf-normalize-plist)
       (defvar leaf-merge-dupkey-values-plist)))))

(provide 'leaf-tests)
;;; leaf-tests.el ends here
