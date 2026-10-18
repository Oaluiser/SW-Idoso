# Alô Diário — protótipo

Ligação diária para o idoso, com resumo para a família. Protótipo em Flutter Web
com dados simulados, publicado no GitHub Pages.

## Fluxo

1. **Dados base** — nome e telefone do idoso; nome, e-mail e WhatsApp do familiar.
2. **Ligação** — horário, 2 a 5 perguntas (de 10) e observações livres.
3. **Calendário** — cada dia mostra o status; clicar abre o resumo. Dias futuros
   permitem deixar um recado. Configurações editam tudo.

Tudo fica salvo no `localStorage` do navegador.

## Dados

O resumo diário segue o JSON do backend (`lib/models.dart` → `CallSummary.fromJson`):
`idoso`, `data_ligacao` (dd/MM/yyyy), `status` (verde | amarelo | vermelho),
`titulo`, `resumo_familia`, `sinais[]`, `humor_geral`, `engajamento`,
`mudancas_vs_historico[]`, `pauta_proxima_ligacao[]`.

Campos extras opcionais usados pelo protótipo: `tentativas[]`, `duracao_min`,
`recado {texto, resposta}`, `solicitacoes[]`, `respostas_perguntas[]`,
`whatsapp_enviado`, `sinais[].alerta`. Status `sem_ligacao` = não atendeu.

O mock (`lib/mock_data.dart`) gera 60 dias de histórico relativos a hoje.

## Rodar

```sh
flutter pub get
flutter run -d chrome
flutter test
```

## Deploy

Push na `main` dispara `.github/workflows/deploy.yml`. No GitHub:
**Settings → Pages → Source: GitHub Actions**.
