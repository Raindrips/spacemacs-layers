(font-lock-add-keywords
 'idris-mode
 `(("\\s ?(?\\(\\\\\\)\\s *\\(\\w\\|_\\|(.*)\\).*?\\s *=>"
    (0
     (progn (compose-region (match-beginning 1) (match-end 1)
                            ?\λ 'decompose-region)
            nil)))))

;;; Commands

(defun idris/switch-to-src ()
  "Pop to the last idris source buffer."
  (interactive)
  (-if-let (buf (car (--filter-buffers (derived-mode-p 'idris-mode))))
      (pop-to-buffer buf)
    (error "No idris buffers")))

(defun idris/just-one-space (id action ctx)
  "Pad parens with spaces."
  (when (and (equal 'insert action)
             (sp-in-code-p id action ctx))
    ;; Insert a leading space, unless
    ;; 1. this is a quoted form
    ;; 2. this is the first position of another list
    ;; 3. this form begins a new line.
    (save-excursion
      (search-backward id)
      (unless (s-matches?
               (rx (or (group bol (* space))
                       (any "," "`" "@" "(" "[" "{")) eol)
               (buffer-substring (line-beginning-position) (point)))
        (just-one-space)))
    ;; Insert space after separator, unless
    ;; 1. this form is at the end of another list.
    ;; 2. this form is at the end of the line.
    (save-excursion
      (search-forward (sp-get-pair id :close))
      (unless (s-matches? (rx (or (any ")" "]" "}")
                                  eol))
                          (buffer-substring (point) (1+ (point))))
        (just-one-space)))))


;;; Smart M-RET

(defun idris/data-start-pos ()
  "Find the start position of the datatype declaration at point."
  (save-excursion
    (end-of-line)
    (when (search-backward-regexp (rx bol (* space) (or "record" "data") eow) nil t)
      (skip-chars-forward " \t")
      (point))))

(defun idris/data-end-pos ()
  "Find the end position of the datatype declaration at point."
  (save-excursion
    (let ((start (point)))

      (goto-char (idris/data-start-pos))
      (forward-line)
      (goto-char (line-beginning-position))

      (let ((end
             (when (search-forward-regexp
                    (rx bol (or (and (* space) eol) (not (any space "|"))))
                    nil t)
               (forward-line -1)
               (line-end-position))))
        (if (and end (<= start end))
            end
          (point-max))))))

(cl-defun idris/data-decl-at-pt ()
  "Return the data declaration at point."
  (-when-let* ((start (idris/data-start-pos))
               (end (idris/data-end-pos)))
    (buffer-substring-no-properties start end)))

(defun idris/at-data-decl? ()
  (-when-let (dd (idris/data-decl-at-pt))
    (let ((lines (s-split "\n" dd)))
      (or (equal 1 (length lines))
          (->> (-drop 1 lines)
            (-all? (~ s-matches? (rx bol (or space "|")))))))))

(defun idris/function-name-at-pt ()
  "Return the name of the function at point."
  (save-excursion
    (search-backward-regexp (rx bol (* space) (group (+ (not (any space ":"))))))
    (let ((s (s-trim (match-string-no-properties 1))))
      (unless (or (-contains? idris-keywords s)
                  (s-blank? s))
        s))))

(defun idris/ret ()
  "Indent and align on newline."
  (interactive "*")
  (if (s-matches? comment-start (current-line))
      (comment-indent-new-line)

    (cond

     ((s-matches? (rx space "->" (* space))
                  (buffer-substring (line-beginning-position) (point)))
      (newline)
      (delete-horizontal-space)
      (indent-for-tab-command))

     ((s-matches? (rx bol (* space) eol) (current-line))
      (delete-horizontal-space)
      (newline))

     (t
      (idris-newline-and-indent)))))

(defun idris/meta-ret ()
  "Create a newline and perform a context-sensitive continuation.
- At functions, create a new case for the function.
- At types, add a 'where' statement if one does not exist.
- At comments, fill paragraph and insert a newline."
  (interactive)
  (cond

   ;; Insert new type decl case below the current one.
   ((s-matches? (rx bol (* space) "|") (current-line))
    (let ((col (save-excursion (back-to-indentation) (current-column))))
      (goto-char (line-end-position))
      (newline)
      (indent-to col))

    (insert "| ")
    (message "New data case"))

   ;; Insert new type decl case below the current one.
   ((and (s-matches? (rx bol (* space) "data") (current-line))
         (not (s-matches? "where" (current-line))))

    (-if-let (col (save-excursion
                    (goto-char (line-beginning-position))
                    (search-forward "=" nil t)
                    (current-column)))
        (progn
          (goto-char (line-end-position))
          (newline)
          (indent-to (1- col)))

      (goto-char (line-end-position))
      (idris-newline-and-indent))

    (insert "| ")
    (message "New data case"))

   ;; Create new function case.
   ((idris/function-name-at-pt)
    (goto-char (line-end-position))
    (let ((fn (idris/function-name-at-pt))
          (col (save-excursion
                 (back-to-indentation)
                 (current-column))))

      (unless (s-matches? (rx bol (* space) eol) (current-line))
        (newline))

      (indent-to-column col)
      (insert fn)
      (just-one-space)))

   ;; Insert new line starting with comma.
   ((s-matches? (rx bol (* space) ",") (current-line))
    (cb-hs:newline-indent-to-same-col)
    (insert ", ")
    (message "New entry"))

   ;; Create a new line in a comment.
   ((s-matches? comment-start (current-line))
    (fill-paragraph)
    (comment-indent-new-line)
    (message "New comment line"))

   (t
    (goto-char (line-end-position))
    (idris/ret)))

  (evil-insert-state))