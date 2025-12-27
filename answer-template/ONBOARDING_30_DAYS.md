# Plano de Onboarding de 30 Dias - Engenheiro DevOps - Plataforma Plooral

Este documento detalha o plano de onboarding de 30 dias para um novo Engenheiro DevOps na equipe da plataforma Plooral. O objetivo é integrar o novo membro da equipe de forma eficaz, garantindo que ele/ela se torne um operador autônomo, seguro e proficiente da plataforma.

## 1. Semana 1: Observação (Dias 1-7)

**Objetivo:** Familiarizar-se com a equipe, ferramentas, processos e a arquitetura geral da plataforma, observando as operações diárias.

### Atividades Dia a Dia
*   **Dia 1:**
    *   Boas-vindas à equipe, introdução aos membros da equipe e estrutura organizacional.
    *   Configuração do ambiente de trabalho (laptop, acesso a contas AWS, GitHub, Slack, Confluence, etc.).
    *   Visão geral do projeto e da missão da Plooral.
*   **Dia 2-3:**
    *   Revisar a arquitetura de alto nível da plataforma Plooral (`CONTEXT.md`).
    *   Leitura do `RUNBOOK.md` (este documento).
    *   Sessão com membro sênior sobre as práticas de CI/CD (CodePipeline).
    *   Introdução às ferramentas de monitoramento (CloudWatch Dashboards e Alarms).
*   **Dia 4-5:**
    *   Observar reuniões diárias (stand-ups) e sessões de planejamento.
    *   Shadowing de um engenheiro sênior em atividades de manutenção rotineiras ou investigações de problemas.
    *   Exploração guiada do console AWS para os principais serviços (ECS, Lambda, RDS, SQS, CloudFront).
*   **Dia 6-7:**
    *   Revisar repositórios de código da API (Node.js) e Worker (Python).
    *   Entender a estrutura de testes e automação existente.
    *   Começar a documentar dúvidas e observações.

### Sistemas para Obter Acesso
*   **AWS Console:** Acesso de Leitura (ReadOnly) aos serviços principais (ECS, Lambda, RDS, SQS, CloudFront, CloudWatch, CodePipeline, SSM, IAM).
*   **GitHub:** Acesso aos repositórios da plataforma Plooral.
*   **Slack:** Membro dos canais da equipe e `#prod-alerts`.
*   **Confluence:** Acesso a toda a documentação existente.
*   **Ferramentas Internas:** Jira (se usado), sistema de gerenciamento de segredos (SSM Parameter Store para leitura).

### Reuniões Chave para Participar
*   Stand-ups Diários da Equipe.
*   Reuniões de Planejamento/Refinamento de Sprint.
*   Reuniões de Arquitetura (se houver).
*   Reuniões de Incidentes (como observador).

### Documentação para Ler
*   `CONTEXT.md` e `REQUIREMENTS.md` (já lidos).
*   `RUNBOOK.md` (este documento).
*   Documentação de projetos específicos no Confluence.
*   `README.md` dos principais repositórios de código.

### Perguntas para a Equipe
*   "Qual é o fluxo de trabalho típico para implantar uma nova funcionalidade?"
*   "Como lidamos com o débito técnico?"
*   "Quais são os maiores desafios operacionais atuais?"
*   "Há algum "código legado" ou "áreas de cuidado" na plataforma?"
*   "Como é o processo de feedback e revisão de código?"

### Sessões de Pair Programming
*   Observar e participar (inicialmente como ouvinte) de sessões de pair programming, focando em como as decisões são tomadas e o código é implementado.

## 2. Semana 2: Operações Guiadas (Dias 8-14)

**Objetivo:** Começar a executar tarefas operacionais com supervisão, solidificando o conhecimento prático.

### Primeiro Deploy Supervisionado
*   Realizar um deploy de uma pequena alteração (ex: atualização de dependência, alteração de texto) em ambiente de staging e, posteriormente, em produção, sob supervisão direta de um engenheiro sênior.
*   Focar no checklist pré-deploy e nos passos de verificação pós-deploy.

### Primeiro Plantão (Backup)
*   Participar do ciclo de plantão (on-call) em função de backup, observando e aprendendo com o engenheiro primário.
*   Acompanhar a triagem de alertas e a execução de playbooks de resposta a alarmes.

### Observação de Resposta a Incidentes
*   Se ocorrer um incidente, participar como observador ativo, focando na comunicação, investigação e resolução, sem a pressão de ser o responsável primário.

### Prática de Operações de Banco de Dados
*   Com supervisão, executar queries de leitura no Aurora (somente instâncias de leitora).
*   Familiarizar-se com o console do RDS e Performance Insights.

### Revisão de Monitoramento
*   Criar um dashboard simples no CloudWatch para um serviço específico.
*   Ajustar ou criar um alarme de teste com base em métricas existentes.

## 3. Semana 3: Operações Independentes (Dias 15-21)

**Objetivo:** Começar a operar a plataforma com mais autonomia, assumindo responsabilidades primárias sob revisão.

### Deploy Solo (com Revisão)
*   Realizar deploys de funcionalidades de médio porte em produção de forma independente.
*   A revisão do deploy e do resultado por um colega sênior ainda é esperada.

### Plantão Primário
*   Assumir o papel de engenheiro primário no ciclo de plantão.
*   Ser o primeiro a responder a alertas e iniciar playbooks de resposta.
*   Ter um engenheiro sênior disponível para escalonamento rápido.

### Treinamento de Comandante de Incidente
*   Assumir o papel de Comandante de Incidente (IC) para um incidente simulado ou de menor prioridade.
*   Focar na orquestração da resposta, comunicação e tomada de decisão.

### Validação do Runbook
*   Utilizar o `RUNBOOK.md` ativamente durante as operações.
*   Propor melhorias e atualizações ao documento com base na experiência prática.

### Revisão de Segurança
*   Revisar as melhores práticas de segurança na AWS (ex: princípio do menor privilégio, rotação de chaves).
*   Verificar o uso de segredos via SSM Parameter Store.

## 4. Semana 4: Propriedade Plena (Dias 22-30)

**Objetivo:** Transição para propriedade plena da plataforma, com capacidade de atuar de forma proativa e gerenciar situações complexas.

### Transição de Propriedade Plena
*   Assumir responsabilidade por um ou mais componentes da plataforma (ex: Monitoramento, CI/CD, Gerenciamento de Acesso).
*   Propor melhorias e otimizações para esses componentes.

### Simulação de Procedimentos de Emergência
*   Participar de um exercício de simulação de desastre ou falha crítica (ex: failover de DB, queda de AZ).
*   Praticar os procedimentos de acesso de emergência.

### Verificação de Contatos de Fornecedores
*   Revisar a lista de contatos de fornecedores e parceiros (AWS TAM, etc.).
*   Entender os canais e processos de escalonamento com fornecedores.

### Transferência Final de Conhecimento
*   Sessões de Q&A com engenheiros experientes para preencher lacunas de conhecimento.
*   Documentar novas informações ou detalhes que ainda não estavam claros.

### Plano de Suporte e Escalonamento da Equipe
*   Entender como e quando escalar problemas para o Platform Lead ou Engineering Manager.
*   Conhecer o processo para solicitar ajuda ou revisão de código de outros membros da equipe.

## 5. Marcos (Milestones)

| Marco | Prazo | Critério de Sucesso |
|---|---|---|
| **Ambiente Configurado** | Fim do Dia 2 | Todos os acessos iniciais concedidos e ambiente de desenvolvimento funcional. |
| **Compreensão da Arquitetura** | Fim da Semana 1 | Ser capaz de explicar a arquitetura principal da plataforma e seus componentes (API, Worker, DB). |
| **Primeiro Deploy em Produção** | Fim da Semana 2 | Realizar um deploy supervisionado em produção, seguindo o checklist e verificações. |
| **Primeiro Plantão Primário** | Fim da Semana 3 | Atuar como on-call primário com sucesso, respondendo a alertas e executando ações básicas. |
| **Contribuição para Runbook** | Fim da Semana 3 | Propor e implementar pelo menos uma melhoria no `RUNBOOK.md` baseada na experiência. |
| **Proposição de Melhoria** | Fim da Semana 4 | Apresentar uma proposta documentada de melhoria ou otimização para um componente da plataforma. |

## 6. Critérios de Saída (Exit Criteria)

Para ser considerado "totalmente operacional" ao final dos 30 dias, o engenheiro deve:

*   **Autonomia em Deploy:** Ser capaz de realizar deploys em produção de forma independente e segura, incluindo rollback se necessário.
*   **Resposta a Incidentes:** Demonstrar capacidade de responder a incidentes P1/P2, usando o `RUNBOOK.md` para investigação, contenção e comunicação.
*   **Troubleshooting Básico:** Conseguir diagnosticar e resolver problemas comuns em ECS, Lambda, Aurora e SQS.
*   **Gerenciamento de Acesso:** Compreender os procedimentos para conceder/revogar acesso e o processo de acesso de emergência.
*   **Conhecimento da Plataforma:** Ter um entendimento sólido de como todos os componentes da plataforma Plooral interagem.
*   **Comunicação:** Comunicar-se de forma clara e eficaz durante incidentes, deploys e discussões técnicas.

## 7. Análise de Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| **Conhecimento Insuficiente** | Média | Alto | Onboarding estruturado, pair programming, sessões de Q&A, revisão de código e operações. |
| **Sobrecarga de Informações** | Alta | Médio | Abordagem gradual (semanas), foco em tarefas práticas, tempo dedicado para leitura e perguntas. |
| **Falha em Operação Crítica** | Baixa | Muito Alto | Supervisão inicial, deploys em staging primeiro, uso de runbooks, failover e rollback testados. |
| **Falta de Acesso/Permissões** | Média | Médio | Checklist de acessos na Semana 1, revisão constante com Platform Lead/Security. |
| **Problemas de Comunicação** | Média | Médio | Incentivo a perguntas, canais de Slack dedicados, feedback contínuo. |

## 8. Plano de Contingência

### O que acontece se membros-chave da equipe estiverem indisponíveis durante seu onboarding?

*   **Designar um Mentor Backup:** Sempre haverá um engenheiro sênior secundário designado como backup do mentor principal para cada semana.
*   **Documentação Centralizada:** O `RUNBOOK.md` e a documentação no Confluence são a fonte primária de verdade. O novo engenheiro deve ser capaz de consultar a documentação para a maioria das perguntas.
*   **Canais de Comunicação Assíncronos:** Utilizar Slack para perguntas que não exigem resposta imediata, permitindo que outros membros da equipe respondam quando disponíveis.
*   **Priorização:** Em caso de indisponibilidade prolongada, priorizar as atividades mais críticas (ex: acesso aos sistemas, participação em plantões) e adiar tarefas menos urgentes.
*   **Engajamento com Gerente:** O Engineering Manager será informado sobre quaisquer desafios e ajudará a realocar recursos ou ajustar o plano conforme necessário.
