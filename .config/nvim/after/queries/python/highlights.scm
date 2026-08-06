; highlight Enum-derived class names (using superclasses field)
(
  (class_definition
    name: (identifier) @enum.class.name
    superclasses: (argument_list
      (identifier) @enum.base
      (#match? @enum.base ".*Enum$")))
)

;; debug: capture *all* class_definition names
(
  (class_definition
    name: (identifier) @all.class.name)
)
