;;; pbook.el -- Format a program listing in plain text.  -*- lexical-binding: t; -*-
;;;
;;; (C) 2014 Rudi Schlatte <rudi@constantly.at>
;;;
;;; * Low-level literate programming
;;;
;;; Converts a source buffer into marked-up text.  This is an implementation
;;; of Luke Gorrie's idea at
;;; [http://lukego.github.io/blog/2012/10/24/readable-programs/] (see
;;; [[https://gist.github.com/lukego/3945964][this gist]] for details).
;;;
;;; Comments starting at column 0 will be converted to text, everything else
;;; becomes code blocks.
;;; 
;;; In principle, any plain-text syntax (org-mode, Markdown, ...) can be used
;;; that can mark code with a per-line prefix.  See `rs-pbook-markup-language'
;;; and its docstring.

;;; * Customization

(defgroup rs-pbook nil "Convert buffer into marked-up text"
  :group 'tools
  :prefix 'rs-pbook)

(defcustom rs-pbook-markup-languages
  '((markdown markdown-mode ".md" "    ")
    (org org-mode ".org" ": "))
  "Alist of supported plain-text markup languages.
This is an alist mapping the name of a markup dialect to a
three-element list.  The first element is the name of the major
mode (as a funcallable symbol), the second element is the
filename extension, the third element is the per-line prefix for
code blocks."
  :type '(alist :key-type (symbol :tag "Name")
                :value-type (group (symbol :tag "Major mode")
                                   (string :tag "Extension")
                                   (string :tag "Code line prefix")))
  :risky t)

(defcustom rs-pbook-markup-language 'org
  "The markup language to use to format code via `rs-pbook'.
Must have an entry in `rs-pbook-markup-languages'."
  :type `(radio ,@(mapcar (lambda (x) (list 'const (car x)))
                          rs-pbook-markup-languages))
  :set-after '(rs-pbook-markup-languages)
  :safe (lambda (value) (member value (mapcar #'car rs-pbook-markup-languages))))

;;; * Code
(defun rs-pbook (flag)
  "Convert buffer into literate program.
Rs-pbook is based on a one-liner of Luke Gorrie.  It converts
your current code buffer into your choice of markdown or org-mode
for easy code reading.

See http://lukego.github.io/blog/2012/10/24/readable-programs/
for the inspiration."
  (interactive "p")
  (let* ((language (if (= 1 flag)
                       rs-pbook-markup-language
                     (intern (completing-read "Target language: "
                                              (mapcar #'first rs-pbook-markup-languages)
                                              nil t nil nil rs-pbook-markup-language))))
         (major-mode-function (second (assoc language rs-pbook-markup-languages)))
         (code-prefix (fourth (assoc language rs-pbook-markup-languages)))
         (output-buffer-name (concat (file-name-sans-extension (buffer-file-name))
                                     (third (assoc language rs-pbook-markup-languages))))
         (text (buffer-string))
         ;; `comment-start-skip' is more precise than `comment-start-skip',
         ;; except that we want to remove one trailing space only.
         (my-comment-start (if (string-suffix-p "*" comment-start-skip)
                               (concat (substring comment-start-skip 0 -1) "?")
                             (comment-start-skip))))
    (with-current-buffer (find-file output-buffer-name)
      (setq text (replace-regexp-in-string "^" code-prefix text))
      (setq text (replace-regexp-in-string (concat "^" code-prefix my-comment-start)
                                           "" text))
      (insert text)
      (goto-char (point-min))
      (funcall major-mode-function)
      (set-buffer-modified-p nil))))

(provide 'rs-pbook)
