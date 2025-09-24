return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  init_options = {
    disableAutomaticTypeAcquisition = true
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json" }
}