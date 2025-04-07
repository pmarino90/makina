import Makina.DSL

makina "test-wth-servers" do
  server host: "example.com"
  server host: "example2.com"
end
