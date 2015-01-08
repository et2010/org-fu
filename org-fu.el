;; Expected files:
;; * gtd.org with level 1: Tasks, Projects
;;
;;   Projects with level 2: elisp, function-args, tiny.el, el-TeX,
;;   Worf, Scientific Articles
;;
;; * ent.org with level 1: Articles, Videos
;; * wiki/stack.org with level 1: Questions

;;* base directory
(defvar org.d "~/Dropbox/org")

(defun org-expand (name)
  (expand-file-name name org.d))

;;* capture
;;** tasks
(require 'org-capture)
(setq
 org-capture-templates
 '(("t" "TODO" entry (file+headline (org-expand "gtd.org") "Tasks")
    "* TODO %^{Brief Description} %^g     \nAdded: %U  %i\n  %?\n"
    :clock-in t :clock-resume t)))
;;** projects
(defvar org-project-list
  '(("ELISP" "e" "elisp")
    ("FARGS" "f" "function-args")
    ("WORF" "w" "worf")
    ("LISPY" "y" "lispy"))
  "List of projects in gtd.org in '(tag key description) format.")

(mapc
 (lambda (project)
   (add-to-list
    'org-capture-templates
    (destructuring-bind (tag key name) project
      `(,key ,name entry (file+olp (org-expand "gtd.org") "Projects" ,name)
             ,(format
               "* TODO %%^{Brief Description}  :%s:\nAdded: %%U  %%i\n  %%?\n"
               tag)
             :clock-in t :clock-resume t))))
 org-project-list)
;;** PDF
(push
 '("p" "Pdf article" entry (file+olp (org-expand "gtd.org") "Projects" "Scientific Articles")
   "* TODO Read %(org-process-current-pdf)%(org-set-tags-to\"OFFICE\")\nAdded: %U %i\n  %?\n")
 org-capture-templates)

(require 'org-attach)
(defun org-process-current-pdf ()
  (let* ((buffer (org-capture-get :buffer))
         (buffer-mode (with-current-buffer buffer major-mode))
         (filename (org-capture-get :original-file)))
    (when (file-directory-p filename)
      (with-current-buffer (org-capture-get :original-buffer)
        (setq filename (dired-get-filename))))
    (when (or (string= (file-name-extension filename) "pdf")
              (string= (file-name-extension filename) "djvu"))
      (let ((org-attach-directory (org-expand "data/"))
            (name (file-name-sans-extension
                   (file-name-nondirectory filename))))
        (org-attach-attach filename nil 'cp)
        (if (string-match "\\[\\(.*\\)\\] \\(.*\\)(\\(.*\\))" name)
            (format "\"%s\" by %s"
                    (match-string 2 name)
                    (match-string 1 name))
          name)))))
;;* protocol
(require 'org-protocol)
(setq org-protocol-default-template-key "l")
(push '("l" "Link" entry (function org-handle-link)
        "* TODO %(org-wash-link)\nAdded: %U\n%(org-link-hooks)\n%?")
      org-capture-templates)

(defun org-wash-link ()
  "Return a pretty-printed top of `org-stored-links'.
Try to remove superfluous information, like website title."
  (let ((link (caar org-stored-links))
        (title (cadar org-stored-links)))
    (org-make-link-string
     link
     (replace-regexp-in-string " - Stack Overflow" "" title))))

(defvar org-link-hook nil)

(defun org-link-hooks ()
  (prog1
      (mapconcat #'funcall
                 org-link-hook
                 "\n")
    (setq org-link-hook)))

(defun org-handle-link ()
  (let ((link (caar org-stored-links))
        file)
    (cond ((string-match "^https://www.youtube.com/" link)
           (org-handle-link-youtube link))
          ((string-match (regexp-quote "http://stackoverflow.com/") link)
           (find-file (org-expand "wiki/stack.org"))
           (goto-char (point-min))
           (re-search-forward "^\\*+ +Questions" nil t))
          (t
           (find-file (org-expand "ent.org"))
           (goto-char (point-min))
           (re-search-forward "^\\*+ +Articles" nil t)))))

(require 'async)
(defun org-handle-link-youtube (link)
  (lexical-let*
      ((file-name (org-trim
                   (shell-command-to-string
                    (concat
                     "youtube-dl \""
                     link
                     "\""
                     " -o \"%(title)s.%(ext)s\" --get-filename"))))
       (dir "~/Downloads/Videos")
       (full-name
        (expand-file-name file-name dir)))
    (add-hook 'org-link-hook (lambda () (format "[[%s][%s]]\n[[%s][%s]]"
                                           dir dir
                                           full-name file-name)))
    (async-shell-command
     (format "youtube-dl \"%s\" -o \"%s\"" link full-name))
    (find-file (org-expand "ent.org"))
    (goto-char (point-min))
    (re-search-forward "^\\*+ +Videos" nil t)))

(provide 'org-fu)

;;; Local Variables:
;;; outline-regexp: ";;\\*+"
;;; End:

;;; org-fu.el ends here
