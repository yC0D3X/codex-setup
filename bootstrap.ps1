# ============================================================
# LOADER / REDIRECIONADOR
# Este é o ÚNICO comando que você precisa usar em qualquer PC:
#
#   irm https://raw.githubusercontent.com/yC0D3X/codex-setup/main/bootstrap.ps1 | iex
#
# Ele apenas repassa a execução para o script real. Se um dia você
# mudar o script de lugar (outro repo, outro gist, outro host),
# edite SÓ a linha abaixo — o comando que você usa nos PCs nunca muda.
# ============================================================

irm "https://raw.githubusercontent.com/yC0D3X/codex-setup/main/instaladorprogramas.ps1" | iex
