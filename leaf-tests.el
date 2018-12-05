;;; leaf-tests.el ---                                -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Naoya Yamashita

;; Author: Naoya Yamashita
;; Keywords: .emacs

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
(require 'cort)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  test settings
;;

(unless (fboundp 'macroexpand-1)
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

(defmacro match-expansion (form value)
  `(should
    (equal (macroexpand-1 ',form) ,value)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  test definition
;;

;; (srt-deftest leaf-test:/disabled-1
;;   (:equal
;;    (leaf foo :disabled t)
;;    'nil))
;; 
;; (srt-deftest leaf-test/:if-1 ()
;;   (match-expansion
;;    (leaf foo :if t)
;;    '(if t
;; 	(progn
;; 	  (require (quote foo) nil nil)))))
;; 
;; (srt-deftest leaf-test/:if-2 ()
;;   (match-expansion
;;    (leaf foo :if (and t t))
;;    '(if (and t t)
;; 	(progn
;; 	  (require (quote foo) nil nil)))))
;; 
;; (srt-deftest leaf-test/:if-3 ()
;;   (match-expansion
;;    (leaf foo :if nil)
;;    '(if nil
;; 	(progn
;; 	  (require (quote foo) nil nil)))))
;; 
;; (srt-deftest leaf-test/:when-1 ()
;;   (match-expansion
;;    (leaf foo :when t)
;;    '(when t
;;       (progn
;; 	(require 'foo nil nil)))))
;; 
;; (srt-deftest leaf-test/:when-2 ()
;;   (match-expansion
;;    (leaf foo :when (and t t))
;;    '(when (and t t)
;;       (progn
;; 	(require 'foo nil nil)))))
;; 
;; (srt-deftest leaf-test/:when-3 ()
;;   (match-expansion
;;    (leaf foo :when nil)
;;    '(when nil
;;       (progn
;; 	(require 'foo nil nil)))))
;; 
;; (srt-deftest leaf-test/:unless-1 ()
;;   (match-expansion
;;    (leaf foo :unless t)
;;    '(unless t
;;       (progn
;; 	(require 'foo nil nil)))))
;; 
;; (srt-deftest leaf-test/:unless-2 ()
;;   (match-expansion
;;    (leaf foo :unless (and t t))
;;    '(unless (and t t)
;;       (progn
;; 	(require 'foo nil nil)))))
;; 
;; (srt-deftest leaf-test/:unless-3 ()
;;   (match-expansion
;;    (leaf foo :unless nil)
;;    '(unless nil
;;       (progn
;; 	(require 'foo nil nil)))))

(provide 'leaf-tests)
;;; leaf-tests.el ends here
