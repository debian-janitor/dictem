(require 'dictem)

;(load-file "dictem.el")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;            Faces             ;;;;;

(defface dictem-reference-define-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((class color)
      (background light))
     (:foreground "blue"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to
a phrase in a DEFINE search."
  :group 'dictem)

(defface dictem-reference-m1-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((class color)
      (background light))
     (:foreground "blue"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to
a phrase in a MATCH search."
  :group 'dictem)

(defface dictem-reference-m2-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "green"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((class color)
      (background light))
     (:foreground "blue"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to
a single word in a MATCH search."
  :group 'dictem)

(defface dictem-reference-dbname-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "white"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "white"))
    (((class color)
      (background light))
     (:foreground "white"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to database"
  :group 'dictem)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;      Low Level Functions     ;;;;;

(defun link-create-link (start end face function &optional data help)
  "Create a link in the current buffer starting from `start' going to `end'.
The `face' is used for displaying, the `data' are stored together with the
link.  Upon clicking the `function' is called with `data' as argument."
  (let ((properties
	 (list 'face face
	       'mouse-face 'highlight
	       'link t
	       'link-data data
	       'link-function function)
	  ))
    (remove-text-properties start end properties)
    (add-text-properties start end properties)))

;;;;;;;   Coloring Functions     ;;;;;;;

(defun dictem-color-define ()
  (interactive)
  (let ((regexp "[{]\\([^{}\n]+\\)[}]\\|^\\(From\\) [^\n]+\\[\\([^\n]+\\)\\]")
	(dbname nil))
    (beginning-of-buffer)
    (while (< (point) (point-max))
      (if (search-forward-regexp regexp nil t)
	  (if (match-beginning 1)
	      (let* ((beg (match-beginning 1))
		     (end (match-end 1))
		     (word
		      (dictem-replace-spaces
		       (buffer-substring-no-properties beg end))))
		(replace-match "\\1")
		(link-create-link
		 (- beg 1) (- end 1)
		 'dictem-reference-define-face
		 'dictem-define-base
		 (list (cons 'word word)
		       (cons 'dbname dbname))
		 ))
	    (let* ((beg (match-beginning 2))
		   (end (match-end 2))
		   (beg-dbname (match-beginning 3))
		   (end-dbname (match-end 3))
		   )
	      (put-text-property beg end 'face 'dictem-reference-dbname-face)
	      (setq dbname
		    (dictem-replace-spaces
		     (buffer-substring-no-properties beg-dbname end-dbname)))
	      (link-create-link
	       beg-dbname end-dbname
	       'dictem-reference-dbname-face
	       'dictem-dbinfo-base
	       (list (cons 'dbname dbname))))
	       )
	(goto-char (point-max))))
  (beginning-of-buffer)))

(defun dictem-color-match ()
  (interactive)
  (let* ((last-database dictem-last-database)
	 (regexp "\\(\"[^\"\n]+\"\\)\\|\\([^ \"\n]+\\)"))
;	 (regexp1 " \"[^\"\n]*\"")
;	 (regexp2 " [^ \n][^ \n]*")
;	 (regexp3 "^[^ :]+"))

    (beginning-of-buffer)
    (while (search-forward-regexp regexp nil t)
      (let* ((beg (match-beginning 0))
	     (end (match-end 0))
	     (first-char (buffer-substring-no-properties beg beg)))
	(cond
	 ((save-excursion (goto-char beg) (= 0 (current-column)))
	  (setq last-database
		(dictem-replace-spaces
		 (buffer-substring-no-properties beg (- end 1))))
	  (link-create-link
	   beg (- end 1)
	   'dictem-reference-dbname-face 'dictem-dbinfo-base
	   (list (cons 'dbname last-database))))
	 ((match-beginning 1)
	  (link-create-link
	   beg end
	   'dictem-reference-m1-face 'dictem-define-base
	   (list (cons 'word
		       (dictem-replace-spaces
			(buffer-substring-no-properties
			 (+ beg 1) (- end 1))))
		 (cons 'dbname last-database))))
	 (t
	  (link-create-link
	   beg end
	   'dictem-reference-m2-face 'dictem-define-base
	   (list (cons 'word
		       (dictem-replace-spaces
			(buffer-substring-no-properties
			 beg end )))
		 (cons 'dbname last-database))))
	 )))
    (beginning-of-buffer)
    ))

;;;;;       On-Click Functions     ;;;;;

(defun dictem-define-on-click (event)
  "Is called upon clicking the link."
  (interactive "@e")

  (mouse-set-point event)
  (let* (
	 (properties (text-properties-at (point)))
	 (data (plist-get properties 'link-data))
	 (fun  (plist-get properties 'link-function))
	 (word   (assq 'word data))
	 (dbname (assq 'dbname data))
	 )
    (if (or word dbname)
	(dictem-run fun
		    (if dbname (cdr dbname) dictem-last-database)
		    (if word (cdr word) nil)
		    nil))))

;(defun dictem-define-with-db-on-click (event)
;  "Is called upon clicking the link."
;  (interactive "@e")
;
;  (mouse-set-point event)
;  (let* (
;	 (properties (text-properties-at (point)))
;	 (word (plist-get properties 'link-data)))
;    (if word
;	(dictem-run 'dictem-define-base (dictem-select-database) word nil))))

(defun dictem-new-search (word &optional all)
;  (interactive)
  (dictem-run
   'dictem-define-base
   dictem-last-database
   word
   nil
   ))

(define-key dictem-mode-map [mouse-2]
  'dictem-define-on-click)

(define-key dictem-mode-map [C-down-mouse-2]
  'dictem-define-with-db-on-click)

(provide 'dictem-opt)
