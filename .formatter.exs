# Used by "mix format"

locals_without_parens = [
  server: 1,
  app: 2,
  from_docker_image: 1,
  docker_registry: 1,
  volume: 2,
  env: 2,
  expose_port: 2,
  proxy: 1,
  publish_on_domain: 2,
  privileged?: 1
]

[
  inputs: ["{mix,.formatter,Makinafile}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
