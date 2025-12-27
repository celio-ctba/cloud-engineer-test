# Candidate Answers

## Candidate Information

| Field | Value |
|-------|-------|
| **Name** | Célio R. Pereira |
| **Email** | celioctba@gmail.com |
| **Date** | 25/12 |
| **Time Spent** | 12hr |

---

## Assumptions

> List any assumptions you made while working through the scenarios. Be explicit — we need to understand your reasoning context.

1. 
2. 
3. 

---

## Scenario 1 — Incident Response

### 1.1 First 10-Minute Actions

> What do you do in the first 10 minutes after being paged?

Meu foco imediato é entender o raio da explosão, reunir informações críticas e me comunicar de forma eficaz. Evitarei tomar quaisquer ações disruptivas imediatas até que eu tenha uma hipótese clara.

| Minuto | Ação | Justificativa |
|---|---|---|
| **0-2** | **Confirmar o recebimento do alerta** em `#prod-alerts` com: "Alerta recebido. Investigando." | Informar à equipe que estou ciente, evitando esforços duplicados. |
| **2-5** | **Revisar o painel de alarmes e eventos recentes.** Vou examinar o `CONTEXT.md` e `cloudwatch_alarms.json`. | Obter uma visão geral de alto nível do que está disparando e a sequência de eventos. Os principais alarmes são latência, erros 5xx, hosts não saudáveis e profundidade da fila SQS. A linha do tempo aponta para a implantação v2.5.0 como um gatilho potencial. |
| **5-7** | **Verificar a saúde do serviço ECS e do banco de dados Aurora.** Vou olhar os eventos do serviço ECS (`ecs_service.log`) e as métricas do RDS (`cloudwatch_metrics.json`, `rds_slowquery.log`). | O alarme `unhealthy-hosts` é crítico. Preciso saber por que as tarefas estão falhando. CPU/conexões altas no BD são um forte indicador de um problema no banco de dados. |
| **7-9** | **Formular uma hipótese rápida.** Com base na implantação da v2.5.0 e nos logs de consulta lenta, minha hipótese inicial é que a nova consulta de recomendação está causando contenção no banco de dados e alta latência. | Isso me dá uma linha específica para investigar. |
| **9-10**| **Comunicar as descobertas iniciais.** Postar uma breve atualização em `#prod-alerts`: "Descoberta inicial: Alta latência e erros se correlacionam com a implantação v2.5.0. Suspeita-se que uma nova consulta ao banco de dados seja a causa. Estou investigando a consulta e proporei um plano de mitigação nos próximos 10 minutos. No momento, não estou tomando nenhuma ação." | Manter as partes interessadas informadas e gerenciar as expectativas. É importante declarar o que eu *não* estou fazendo para evitar pânico ou ações prematuras. |

**O que eu NÃO farei:**

*   **Reverter imediatamente a implantação.** Embora seja um culpado provável, uma reversão é disruptiva. Preciso ter certeza de que é a decisão certa.
*   **Reiniciar serviços.** Isso pode destruir dados forenses valiosos e pode não resolver o problema subjacente.
*   **Desativar o WAF.** O WAF é provavelmente um sintoma (bloqueando tentativas legítimas), não a causa. Desativá-lo poderia nos expor a ameaças reais.

### 1.2 Alarm Correlation

> How do you correlate the alarms? What story do they tell?

Os alarmes contam uma história clara de uma falha em cascata originada na camada da aplicação e impactando todo o ciclo de vida da solicitação.

*   **Indicador Principal:** `plooral-api-p99-latency` (14:17 UTC). Este foi o primeiro sinal de problema, indicando que a própria aplicação estava ficando lenta.
*   **A História:**
    1.  **Alta Latência (`plooral-api-p99-latency`):** A aplicação começa a levar mais tempo para processar as solicitações. Esta é a raiz do problema.
    2.  **Erros 5xx (`plooral-api-5xx-rate`):** À medida que as solicitações expiram, o ALB e outros serviços upstream começam a retornar erros 5xx. O `alb_access.log` mostra erros `504` (Gateway Timeout) e `502` (Bad Gateway).
    3.  **Hosts Não Saudáveis (`plooral-api-unhealthy-hosts`):** As verificações de saúde do ECS, que provavelmente estão atingindo um endpoint de verificação de saúde agora lento, começam a falhar. Isso faz com que o serviço ECS recicle as tarefas, piorando o problema, pois as novas tarefas também podem falhar. O `ecs_service.log` confirma isso, mostrando tarefas falhando com códigos `504` e erros `OOMKilled`.
    4.  **Profundidade da Fila SQS (`plooral-tasks-queue-depth`):** A Lambda `plooral-worker`, que processa mensagens da fila SQS, também é provavelmente impactada pelo banco de dados lento. Ela não consegue processar mensagens rápido o suficiente, fazendo com que a fila aumente. O `lambda.log` e `sqs_metrics.json` confirmam isso, mostrando timeouts do banco de dados e uma fila crescente.
    5.  **Pico de Bloqueios no WAF (`plooral-waf-block-spike`):** Este é um **sintoma**, não uma causa. À medida que os usuários encontram erros, eles tentam novamente suas solicitações, levando a um pico de tráfego de usuários legítimos. Isso aciona a regra de limitação de taxa do WAF. O `waf_sample_requests.log` mostra agentes de usuário de aparência legítima sendo bloqueados. Esta é uma pista falsa em termos de causa raiz, mas um indicador claro do impacto no usuário.
    6.  **Conexões Aurora (`plooral-aurora-connections`):** Este é um sintoma direto da consulta lenta. As consultas de longa duração estão mantendo as conexões abertas, levando ao esgotamento do pool de conexões.

### 1.3 Hypothesis Ranking

> List your hypotheses in order of likelihood. Explain your ranking.

| Rank | Hipótese | Evidência de Suporte | Evidência Contrária |
|---|---|---|---|
| 1 | A nova implantação v2.5.0 introduziu uma consulta de banco de dados ineficiente que está causando alta latência e contenção de recursos. | - **Cronologia:** O incidente começou minutos após a conclusão da implantação v2.5.0. <br>- **Logs:** `rds_slowquery.log` mostra uma nova consulta muito cara (`-- NEW QUERY IN v2.5.0 - User Recommendations`) com `Query_time` e `Lock_time` altos a partir das 14:15 UTC. <br>- **Métricas:** `cloudwatch_metrics.json` mostra a CPU e as conexões do Aurora aumentando após as 14:10 UTC. <br>- **Mudança no Código:** `CONTEXT.md` afirma explicitamente que a mudança da v2.5.0 foi uma "Nova consulta de banco de dados para recomendações de usuários" que "não foi revisada por um DBA". | Nenhuma. A evidência é esmagadora. |
| 2 | Um ator malicioso está lançando um ataque DDoS, causando a alta carga e acionando o WAF. | - **Alarme do WAF:** O alarme `plooral-waf-block-spike` está disparando. <br>- **Aumento de Tráfego:** `cloudwatch_metrics.json` mostra um leve aumento no `RequestCount`. | - **Logs do WAF:** `waf_sample_requests.log` mostra agentes de usuário legítimos e uma nota de que provavelmente são novas tentativas. <br>- **Concentração Geográfica:** O pico de tráfego é de `ap-southeast-1`, que pode ser uma base de usuários legítima. Um DDoS sofisticado provavelmente seria mais distribuído. <br>- **A consulta lenta:** Um ataque DDoS não explicaria o aparecimento súbito de uma nova consulta lenta nos logs. |
| 3 | Uma dependência downstream (por exemplo, uma API externa) está lenta ou indisponível, fazendo com que as solicitações fiquem presas. | - **Erros 5xx:** A aplicação está retornando erros 5xx, que podem ser causados por falhas downstream. | - **Nenhuma Evidência:** Não há menção de nenhuma dependência externa no diagrama de arquitetura ou nos logs. <br>- **Métricas do Banco de Dados:** As métricas do Aurora apontam diretamente para o banco de dados como o gargalo, não um serviço externo. |

### 1.4 Immediate Mitigation

> What mitigation steps do you take? In what order?

São 14:25 UTC. Meu objetivo é restaurar o serviço o mais rápido e seguro possível. A evidência para a Hipótese #1 é muito forte.

| Passo | Ação | Resultado Esperado | O que Pode Dar Errado? | Como Verificar o Sucesso |
|---|---|---|---|---|
| 1 | **Iniciar a Reversão (Rollback) do Serviço ECS `plooral-api` para v2.4.1** | A consulta ineficiente será removida da aplicação. Isso deve reduzir imediatamente a carga no banco de dados. | A reversão pode falhar, ou a imagem v2.4.1 pode ter seus próprios problemas (improvável, pois era a versão estável anterior). A infraestrutura (CodeDeploy) pode ter problemas. | - Monitorar os eventos do serviço ECS para garantir que a reversão seja concluída com sucesso e que todas as tarefas estejam executando a v2.4.1. <br>- Observar a métrica `TargetResponseTime_p99` no CloudWatch; ela deve começar a diminuir significativamente em minutos. |
| 2 | **Monitorar Métricas Chave** | Conforme a reversão avança, espero ver uma recuperação rápida. | O sistema pode não se recuperar, indicando um problema diferente ou adicional. | - **`plooral-api-p99-latency`:** Deve cair abaixo do limiar de 2000ms. <br>- **`plooral-api-5xx-rate`:** Deve cair para perto de zero. <br>- **`plooral-api-unhealthy-hosts`:** Deve ir para 0 à medida que as tarefas se tornam saudáveis. <br>- **`plooral-aurora-cpu` & `plooral-aurora-connections`:** Devem diminuir para os níveis normais. <br>- **`plooral-tasks-queue-depth`:** Deve começar a diminuir à medida que a Lambda do worker consegue processar as mensagens novamente. |
| 3 | **Comunicar o Status** | Manter as partes interessadas informadas sobre a mitigação e recuperação em andamento. | A má comunicação pode causar confusão. | - Postar uma atualização em `#prod-alerts`: "Mitigação em andamento. Revertendo `plooral-api` para v2.4.1 para resolver a suspeita de consulta ruim. Monitorando a recuperação. Próxima atualização em 5 minutos." <br>- Assim que as métricas se recuperarem, postar: "A reversão foi concluída e as métricas estão voltando ao normal. O incidente imediato está resolvido. Estamos agora em fase de monitoramento." |

### 1.5 Permanent Fix

> What is the root cause? What permanent fix do you propose?

**Causa Raiz:** A implantação da `plooral-api` v2.5.0 introduziu uma nova consulta SQL não otimizada e não revisada para recomendações de usuários. Esta consulta realizava um `CROSS JOIN` entre `users` e `jobs` e continha várias subconsultas caras, levando a tempos de consulta extremamente longos, alta contenção de bloqueio e, finalmente, esgotamento de recursos do banco de dados (CPU e conexões).

**Correções Permanentes:**

*   **Mudanças no Código:**
    *   **Reescrever a Consulta:** A consulta de recomendação precisa ser completamente reescrita. O `CROSS JOIN` é inaceitável. A lógica deve ser otimizada, provavelmente quebrando-a em consultas menores e mais direcionadas ou usando uma abordagem totalmente diferente (por exemplo, um mecanismo de recomendação pré-calculado).
    *   **Adicionar Indexação:** Analisar a consulta e adicionar os índices de banco de dados apropriados às tabelas envolvidas (`users`, `jobs`, `user_skills`, `job_skills`, `company_reviews`).
    *   **Implementar Timeouts e Circuit Breakers:** O código da aplicação deve ter timeouts para todas as consultas ao banco de dados e um padrão de circuit breaker para evitar que uma única consulta lenta derrube toda a aplicação.

*   **Mudanças no Processo:**
    *   **Revisão Obrigatória pelo DBA:** Todas as consultas de banco de dados novas ou modificadas devem ser revisadas e aprovadas por um DBA antes de serem mescladas na branch principal.
    *   **Teste de Carga:** Novas funcionalidades complexas como este mecanismo de recomendação devem ser testadas sob carga em um ambiente de homologação (staging) que espelhe a escala de produção. Isso teria capturado o problema de desempenho antes que chegasse à produção.
    *   **Implantações Canário (Canary Deployments):** Em vez de uma implantação contínua (rolling), use uma estratégia de implantação canário. Isso teria exposto o problema a um pequeno subconjunto de usuários, permitindo uma reversão rápida com impacto mínimo.

*   **Guardiões (Guardrails):**
    *   **Alarmes mais Rígidos no CloudWatch:**
        *   Implementar um alarme no `Lock_time` no log de consultas lentas.
        *   Diminuir o limiar para o alarme `p99-latency` para ser mais sensível.
        *   Adicionar um alarme para a utilização de memória do ECS para capturar coisas como o erro `OOMKilled`.
    *   **Reversões Automatizadas:** Configurar a implantação do ECS para reverter automaticamente com base em limiares de alarme específicos do CloudWatch (por exemplo, se a taxa de 5xx exceder uma certa porcentagem por alguns minutos após uma implantação).
    *   **Análise de Consultas no CI/CD:** Integrar uma ferramenta ao pipeline de CI/CD que analise consultas e sinalize possíveis problemas de desempenho (por exemplo, `CROSS JOIN`, falta de índices).

### 1.6 Postmortem Outline

> Provide a brief postmortem structure for this incident.

### Postmortem: Incidente P0 da API Plooral - 15/01/2024

*   **1. Sumário Executivo:**
    *   Um incidente P0 ocorreu em 15 de janeiro de 2024, das 14:15 às 14:35 UTC (20 minutos), causando alta latência, erros e degradação do serviço para todos os usuários. O incidente foi causado por uma nova consulta de banco de dados não otimizada, implantada na versão v2.5.0. O problema foi mitigado com a reversão da implantação para a versão anterior.

*   **2. Resumo do Impacto:**
    *   **Impacto no Cliente:** Os usuários experimentaram carregamentos de página lentos, erros (5xx) e incapacidade de acessar o serviço. Um subconjunto de usuários em `ap-southeast-1` foi bloqueado pelo WAF.
    *   **Métricas:**
        *   Latência P99: Pico de 4.200ms
        *   Taxa de 5xx: Pico de 3.2%
        *   Profundidade da Fila SQS: Aumentou para mais de 14.000 mensagens
    *   **Impacto no Negócio:** Experiência do usuário degradada, potencial perda de confiança do usuário.

*   **3. Linha do Tempo (UTC):**
    *   14:00: Início da implantação da `plooral-api` v2.5.0.
    *   14:05: Implantação concluída.
    *   14:15: Disparo do alarme `plooral-api-p99-latency`.
    *   14:17: Alerta do Slack recebido, início do incidente.
    *   14:18: Disparo do alarme `plooral-api-unhealthy-hosts`.
    *   14:20: Disparo do alarme `plooral-tasks-queue-depth`.
    *   14:22: Disparo do alarme `plooral-waf-block-spike`.
    *   14:25: Engenheiro de plantão inicia a reversão para a v2.4.1.
    *   14:35: Reversão concluída, métricas voltam ao normal. Incidente mitigado.
    *   14:45: Incidente declarado resolvido.

*   **4. Análise da Causa Raiz:**
    *   **Causa Direta:** O lançamento da `plooral-api` v2.5.0 incluiu uma nova consulta SQL altamente ineficiente para recomendações de usuários.
    *   **Fatores Contribuintes:**
        *   A consulta usava um `CROSS JOIN` e subconsultas caras, levando a uma alta carga no banco de dados.
        *   A nova consulta não foi revisada por um DBA.
        *   A funcionalidade não foi testada sob carga antes do lançamento.
        *   A estratégia de implantação contínua expôs todos os usuários ao problema de uma vez.

*   **5. Itens de Ação:**
    | # | Item de Ação | Responsável | Prazo |
    |---|---|---|---|
    | 1 | Reescrever e otimizar a consulta de recomendação de usuário. | @backend-lead | 22/01/2024 |
    | 2 | Implementar um processo de revisão obrigatória pelo DBA para todas as consultas novas/modificadas. | @head-of-engineering | 29/01/2024 |
    | 3 | Configurar um ambiente de homologação para testes de carga de novas funcionalidades. | @devops-lead | 12/02/2024 |
    | 4 | Configurar reversões de implantação automatizadas com base em alarmes chave do CloudWatch. | @devops-lead | 05/02/2024 |
    | 5 | Processar com segurança o backlog do SQS do incidente. | @backend-lead | 16/01/2024 |
    | 6 | Ajustar as regras de limitação de taxa do WAF para serem mais resilientes a tempestades de novas tentativas. | @security-lead | 05/02/2024 |

*   **6. Lições Aprendidas:**
    *   **O que correu bem:** O engenheiro de plantão identificou rapidamente a causa provável e executou uma reversão bem-sucedida. As métricas e logs disponíveis foram suficientes para diagnosticar o problema.
    *   **O que poderia ser melhorado:** Nossas verificações pré-implantação são insuficientes. Precisamos introduzir revisões formais de DBA e testes de carga para mudanças de alto impacto.
    *   **Onde tivemos sorte:** A reversão foi bem-sucedida e a infraestrutura subjacente estava estável. Se o problema fosse mais complexo, a interrupção poderia ter sido muito mais longa.

---

## Scenario 2 — CI/CD and Deployments

### 2.1 Pipeline Issues Identified

> What problems did you find in the pipeline configuration?

| Problema | Arquivo | Linha/Seção | Gravidade | Impacto |
| --- | --- | --- | --- | --- |
| Nenhum estágio de aprovação manual para produção | `codepipeline.json` | `stages` | CRÍTICO | Alterações não aprovadas podem ser implantadas em produção, causando possíveis interrupções. |
| O tempo limite do estágio de construção é muito longo | `codepipeline.json` | `Build stage configuration` | MÉDIO | Falhas de compilação consomem tempo e recursos desnecessários. |
| A imagem do contêiner não é atualizada dinamicamente | `ecs_taskdef.json` | `containerDefinitions[0].image` | CRÍTICO | A mesma imagem de contêiner é implantada todas as vezes, impedindo a implantação de novas versões. |
| O estágio de implantação não tem reversão automática | `codepipeline.json` | `Deploy stage` | ALTO | Falhas de implantação exigem intervenção manual, aumentando o tempo de inatividade. |
| As credenciais do AWS são codificadas no buildspec | `buildspec.yml` | `pre_build commands` | CRÍTICO | As credenciais do AWS são expostas em texto simples, levando a riscos de segurança. |
| A verificação de integridade do ECS é muito agressiva | `ecs_taskdef.json` | `healthCheck` | MÉDIO | Implantações lentas devido a falhas na verificação de integridade, mesmo com a integridade do aplicativo. |
| O tratamento de segredos não está configurado | `ecs_taskdef.json` | `containerDefinitions[0].secrets` | ALTO | O `JWT_SECRET` é tratado como uma variável de ambiente regular, não como um segredo. |

### 2.2 Fixed Configurations

> Describe your fixes. Reference the corrected files you committed.

- **Nenhum estágio de aprovação manual para produção:** adicione um estágio de aprovação manual no `codepipeline.json` antes do estágio de implantação para garantir que as alterações sejam revisadas antes de irem para a produção.
- **O tempo limite da fase de compilação é muito longo:** Reduza o tempo limite de `60` para `30` minutos no `codepipeline.json` para evitar que as compilações travem e consumam recursos.
- **A imagem do contêiner não é atualizada dinamicamente:** modifique o `ecs_taskdef.json` para usar um espaço reservado (`<IMAGE1_NAME>`) para o URL da imagem e crie um `imagedefinitions.json` para mapear dinamicamente a imagem recém-construída durante a implantação.
- **A fase de implantação não tem reversão automática:** ative a reversão automática no `codepipeline.json` para reverter automaticamente para a última implantação bem-sucedida em caso de falha.
- **Credenciais do AWS codificadas no buildspec:** remova as credenciais codificadas do `buildspec.yml` e use as funções do IAM para o CodeBuild para conceder as permissões necessárias com segurança.
- **A verificação de integridade do ECS é muito agressiva:** ajuste os limites de verificação de integridade no `ecs_taskdef.json` para `retries` mais altos e `timeout` mais longo para evitar falhas de implantação falso-positivas.
- **O tratamento de segredos não está configurado:** modifique o `ecs_taskdef.json` para carregar o `JWT_SECRET` do AWS Secrets Manager, evitando a exposição do segredo.

### 2.3 Manual Approval Stage

> How did you add the manual approval gate for production?

Para adicionar um portão de aprovação manual, inclua um novo estágio no `codepipeline.json` antes do estágio de `Deploy` com `actionTypeId` definido como `ManualApproval`.

- **Mudança de configuração:** Adicione um estágio de aprovação manual ao pipeline.
- **Notificação:** notifique o `Slack channel` dos engenheiros de DevOps.
- **Informações para o aprovador:** o aprovador deve ver o `commit ID`, a `mensagem de commit` e um `link` para o `diff`.
- **Política de tempo limite:** defina um tempo limite de 4 horas. Se nenhuma ação for tomada, a aprovação será rejeitada automaticamente.

### 2.4 ECS Task Definition Fixes

> What was wrong with the task definition? How did you fix it?

- **Alocação de memória/CPU:** alocação de `CPU` e `memória` ajustada com base nas métricas de desempenho do aplicativo.
- **Configuração da verificação de integridade:** limites de verificação de integridade ajustados para evitar falhas falso-positivas.
- **Referência da imagem do contêiner:** alterado para um espaço reservado dinâmico (`<IMAGE1_NAME>`).
- **Gerenciamento de segredos:** `JWT_SECRET` reconfigurado para ser carregado do AWS Secrets Manager.

### 2.5 Rollback Strategy

> Describe the rollback procedure for a failed deployment.

A reversão para uma implantação com falha é automatizada. O `CodeDeploy` reverte automaticamente para a última revisão bem-sucedida se a implantação falhar.

- **Como acionar a reversão:** o `CodeDeploy` aciona automaticamente a reversão em caso de falha.
- **O que verificar após a reversão:** verifique se a `versão anterior` está estável.
- **Quanto tempo leva a reversão:** a reversão normalmente leva de 5 a 10 minutos.
- **Comunicação durante a reversão:** notifique a equipe de DevOps por meio de um `canal do Slack` e atualize a página de `status`.

### 2.6 Safe Deployment Flow

> Document the complete safe deployment flow from commit to production.

1. **Commit:** um desenvolvedor envia o código para o `branch principal`.
2. **Fonte:** o `CodePipeline` detecta a alteração e aciona o pipeline.
3. **Construção:** o `CodeBuild` compila o código, executa testes e cria uma `imagem Docker`.
4. **Verificações automatizadas:** testes de unidade, `linting` e verificação de vulnerabilidade.
5. **Aprovação manual:** o pipeline aguarda a aprovação manual. Um `gerente de engenharia` aprova.
6. **Implantação:** o `CodeDeploy` executa uma implantação contínua no `cluster ECS`.
7. **Monitoramento:** monitore a `taxa de erros` e a `latência`. Se os limites forem excedidos, reverta.
8. **Gatilhos de reversão:** acione uma reversão automática se as `verificações de integridade da implantação falharem` ou se os `alarmes do CloudWatch` forem acionados.

---

## Scenario 3 — Data and Messaging

### 3.1 Migration Risk Assessment

> What risks do you see in the proposed migration?

| Risco | Severidade | Mitigação |
| :--- | :--- | :--- |
| Bloqueio de Tabela de Longa Duração | Crítico | Em vez de `ALTER TABLE` diretamente, use uma ferramenta de migração de esquema online como `gh-ost` ou `pt-online-schema-change`, ou execute a migração em etapas. Para adicionar colunas com valores padrão, use `ADD COLUMN` com um `DEFAULT` que não bloqueia, e preencha os dados em um processo em segundo plano separado. |
| Criação de Índice com Bloqueio | Alto | Use a opção `CREATE INDEX CONCURRENTLY` para criar índices sem bloquear as escritas na tabela `users`. Monitore o impacto no desempenho, pois pode consumir mais recursos e demorar mais. |
| Atualizações de Dados de Longa Duração | Alto | Execute as instruções `UPDATE` em lotes para evitar transações de longa duração que possam causar problemas de bloqueio e acúmulo de WAL. Use um `WHERE` para filtrar os usuários que já foram atualizados. |
| Complexidade da Reversão | Médio | O script de reversão fornecido está incompleto. Ele remove as colunas, mas não lida com a restauração da antiga restrição `fk_job_applications_user` ou a remoção dos índices. Um script de reversão mais abrangente é necessário. |
| Impacto no Desempenho | Alto | A migração, especialmente as atualizações de dados e a criação de índices, consumirá recursos significativos da CPU e de E/S, o que pode impactar o desempenho do banco de dados para as aplicações. A migração deve ser agendada para um período de baixo tráfego. |
| Integridade dos Dados | Médio | A lógica de preenchimento para `recommendation_score` pode não ser precisa e pode levar a valores inesperados. Valide a lógica com um DBA e teste em um ambiente de homologação. |

### 3.2 Safe Rollout Plan

> How would you safely execute this migration?

**Checklist Pré-Migração:**
1.  **Revisão do DBA:** A migração deve ser revisada e aprovada por um DBA.
2.  **Teste em Homologação:** A migração deve ser testada em um ambiente de homologação com um volume de dados semelhante ao da produção para medir o tempo de execução e o impacto no desempenho.
3.  **Backup:** Faça um snapshot manual do banco de dados Aurora imediatamente antes de iniciar a migração.
4.  **Comunicação:** Notifique todas as partes interessadas (equipes de desenvolvimento, produto e suporte) sobre a janela de manutenção programada.
5.  **Ponto de Verificação de Sucesso:** Defina claramente o que constitui uma migração bem-sucedida (por exemplo, todas as etapas concluídas sem erros e a aplicação está totalmente funcional).

**Plano de Execução Passo a Passo:**
1.  **Anunciar Janela de Manutenção:** Comunique que a migração começará e que o desempenho pode ser afetado.
2.  **Modo de Manutenção (Se Necessário):** Se for decidido que a aplicação precisa ser colocada em modo de manutenção para evitar inconsistências de dados, faça isso.
3.  **Execução da Migração (fora do horário de pico):**
    *   Execute a criação de índices com `CREATE INDEX CONCURRENTLY`.
    *   Execute as modificações de `ALTER TABLE` usando uma abordagem sem bloqueio ou durante uma janela de manutenção curta.
    *   Execute as atualizações de dados (`UPDATE`) em lotes para evitar transações longas.
4.  **Monitoramento:** Monitore ativamente as principais métricas do banco de dados (CPU, conexões, latência de consulta) durante a migração.
5.  **Verificação:** Após a conclusão da migração, execute um conjunto de testes de verificação para garantir que a aplicação esteja funcionando como esperado e que os dados estejam consistentes.
6.  **Anunciar Conclusão:** Comunique que a migração foi concluída com sucesso.

**Procedimento de Reversão:**
1.  **Decisão de Reversão:** Se os limiares de monitoramento forem violados (por exemplo, a utilização da CPU exceder 90% por mais de 5 minutos) ou se a migração falhar, a decisão de reverter deve ser tomada.
2.  **Executar Script de Reversão:** Execute o script de reversão (aprimorado) para reverter as alterações no esquema.
3.  **Restaurar do Backup (Pior Caso):** Se o script de reversão falhar, restaure o banco de dados a partir do snapshot pré-migração. Isso resultará em tempo de inatividade.

**Plano de Comunicação:**
*   **Antes:** Envie um e-mail e uma mensagem no Slack para as equipes relevantes 24 horas e 1 hora antes da janela de manutenção.
*   **Durante:** Forneça atualizações de status em um canal do Slack dedicado à medida que a migração progride.
*   **Depois:** Envie um e-mail e uma mensagem no Slack confirmando a conclusão bem-sucedida ou a reversão da migração.

### 3.3 Monitoring During Migration

> What do you monitor during the migration? What thresholds trigger rollback?

**Métricas Chave a Serem Observadas:**
*   **Utilização da CPU:** Para garantir que o banco de dados não fique sobrecarregado.
*   **Conexões de Banco de Dados:** Para garantir que o pool de conexões não se esgote.
*   **Latência da Query (Insights de Desempenho):** Para identificar consultas lentas causadas pela migração.
*   **Atraso de Réplica de Leitura:** Para garantir que as réplicas de leitura não fiquem muito para trás.
*   **Uso do Log de Transações (WAL):** Para monitorar a taxa de geração de logs, que pode indicar um grande número de escritas.

**Limiares que Indicam Problemas:**
*   **Utilização da CPU:** > 85% por mais de 10 minutos.
*   **Conexões de Banco de Dados:** > 95% do máximo (`max_connections`).
*   **Latência da Query:** Aumento de 2x na latência média para consultas críticas da aplicação.
*   **Atraso de Réplica:** > 60 segundos.
*   **Taxa de Geração de WAL:** Aumento de 5x em relação à linha de base normal.

**Gatilhos de Reversão:**
*   A migração falha ao ser concluída devido a um erro.
*   Qualquer métrica crítica excede seu limiar de reversão por um período sustentado (por exemplo, CPU > 90% por 5 minutos).
*   A funcionalidade crítica da aplicação fica inoperante.

**Monitoramento Pós-Migração:**
Monitore de perto o desempenho do banco de dados por pelo menos **24 horas** após a migração para garantir que não haja problemas de desempenho introduzidos pelas novas alterações de esquema.

### 3.4 DLQ Handling

> How do you handle the messages in the DLQ?

1.  **Análise e Categorização:**
    *   Primeiro, analise uma amostra das mensagens na DLQ para entender as razões das falhas. O arquivo `sqs_dlq_messages.json` já fez isso, categorizando as mensagens em `safeToRetry` e `doNotRetry`.
    *   **Não Tentar Novamente (36 mensagens):** Mensagens que falharam devido a erros permanentes (por exemplo, "User not found", "ValidationError") não devem ser reprocessadas. Elas devem ser arquivadas em um bucket S3 para análise de causa raiz e, em seguida, excluídas da DLQ.
    *   **Seguro para Tentar Novamente (198 mensagens):** Mensagens que falharam devido a problemas transitórios durante o incidente (por exemplo, "Database connection timeout", "Connection pool exhausted") são candidatas à re-leitura.

2.  **Estratégia de Reprocessamento:**
    *   **Ordem:** Não há uma ordem estrita necessária com base nas amostras, mas se houvesse dependências (por exemplo, um evento de `update` dependendo de um evento de `create`), elas precisariam ser processadas em ordem cronológica.
    *   **Idempotência:** Antes de reprocessar, verifique se o consumidor do Lambda é idempotente. Se não for, reprocessar mensagens pode causar ações duplicadas (por exemplo, enviar a mesma notificação várias vezes). Se a idempotência não for garantida, a lógica precisará ser adicionada ao consumidor para rastrear os IDs de mensagem processados.
    *   **Reprocessamento em Lotes:** Reprocesse as mensagens seguras para nova tentativa em pequenos lotes (por exemplo, 20-50 mensagens de cada vez) durante períodos de baixo tráfego para evitar sobrecarregar o banco de dados novamente. Monitore o desempenho do sistema de perto durante este processo.

3.  **Prevenção de Problemas Futuros:**
    *   Corrija os bugs no código do produtor que estão causando mensagens inválidas (`ValidationError`).
    *   Implemente chaves de idempotência no consumidor do Lambda para evitar o processamento duplicado no futuro.

### 3.5 Alarm Adjustments

> What alarm changes do you recommend?

| Alarme Recomendado | Métrica | Limiar | Descrição |
| :--- | :--- | :--- | :--- |
| **SQS DLQ - Mensagens Visíveis** | `ApproximateNumberOfMessagesVisible` | `> 10` por 1 hora | Alerta se as mensagens começarem a se acumular na DLQ, indicando um problema persistente com o processador de mensagens. |
| **SQS - Idade da Mensagem Mais Antiga** | `ApproximateAgeOfOldestMessage` | `> 3600` segundos (1 hora) | Alerta se as mensagens não estiverem sendo processadas a tempo, o que pode indicar um problema com os consumidores do SQS. |
| **EventBridge - Falhas de Invocação de Destino** | `FailedInvocations` | `> 5` em 5 minutos | Alerta se o EventBridge não conseguir entregar eventos a um destino (por exemplo, SNS, SQS), indicando um problema de permissão ou configuração. |
| **Aurora - Utilização da CPU** | `CPUUtilization` | `> 80%` por 15 minutos | Ajuste o alarme existente para ser mais sensível e alertar mais cedo sobre a alta utilização da CPU. |
| **Aurora - Conexões de Banco de Dados** | `DatabaseConnections` | `> 270` (90% do máximo) | Alerta quando o número de conexões se aproxima do limite, permitindo uma intervenção proativa antes que as conexões sejam rejeitadas. |
| **Lambda - Throttles** | `Throttles` | `> 0` | Alerta se as funções do Lambda estiverem sendo limitadas, o que pode indicar a necessidade de aumentar a concorrência provisionada. |
| **Lambda - Erros** | `Errors` | `> 5%` da taxa de invocação | Alerta se a taxa de erro de uma função do Lambda exceder um nível aceitável. |

---

## Scenario 4 — Security and Edge

### 4.1 IAM Policy Issues

> What problems exist in the IAM policies? How did you fix them?

| Problema | Nível de Risco | Correção Aplicada | Justificativa |
| --- | --- | --- | --- |
| `rds:*` na policy `plooral-ecs-task-role-policy` | Crítico | Substituir `rds:*` por permissões mais granulares como `rds-db:connect` e especificar o ARN do banco de dados. | A permissão `rds:*` concede controle total sobre todas as instâncias RDS, incluindo a capacidade de excluí-las. A correção limita o acesso apenas à conexão com o banco de dados específico da aplicação, seguindo o princípio do menor privilégio. |
| `sqs:*` e `sns:*` na policy `plooral-ecs-task-role-policy` | Alto | Especificar os ARNs das filas SQS e tópicos SNS que a aplicação precisa acessar. | O uso de curingas (`*`) para recursos permite que a role acesse qualquer fila ou tópico, o que é um risco de segurança. A correção restringe o acesso aos recursos estritamente necessários. |
| `ssm:PutParameter` e `ssm:DeleteParameter` na policy `plooral-ecs-task-role-policy` | Médio | Remover as ações `ssm:PutParameter` e `ssm:DeleteParameter` e restringir o `Resource` para `arn:aws:ssm:us-east-1:123456789012:parameter/plooral/prod/*` | A role de uma aplicação normalmente não precisa de permissão para criar ou deletar parâmetros. A correção remove essas permissões e restringe o acesso de leitura aos parâmetros da aplicação. |
| `s3:*` na policy `plooral-ecs-task-role-policy` | Crítico | Especificar o nome do bucket e as ações S3 necessárias (ex: `s3:GetObject`, `s3:PutObject`). | A permissão `s3:*` em todos os recursos (`*`) permite que a role acesse, modifique e exclua qualquer objeto em qualquer bucket S3 na conta. A correção limita o acesso a um bucket específico e apenas às ações necessárias. |
| `kms:Decrypt` e `kms:GenerateDataKey` em `Resource: "*"` na `plooral-ecs-task-role-policy` | Alto | Especificar o ARN da chave KMS usada para criptografar os parâmetros do SSM e outros dados. | O acesso a todas as chaves KMS (`*`) é desnecessariamente amplo. A correção restringe o acesso apenas à chave KMS específica usada pela aplicação. |
| `secretsmanager:GetSecretValue` em `Resource: "*"` na `plooral-ecs-execution-role-policy` | Alto | Especificar o ARN do segredo que precisa ser acessado. | Permitir o acesso a todos os segredos no Secrets Manager é um risco de segurança significativo. A correção limita o acesso apenas ao segredo específico necessário para a execução da tarefa ECS. |
| `xray:PutTraceSegments` e `xray:PutTelemetryRecords` em `Resource: "*"` | Baixo | Manter como está. | Para o X-Ray, o recurso (`Resource`) é sempre `*`, então não há como restringir mais. |

### 4.2 Trust Relationship Explanation

> Explain the trust relationships. Are they correct?

A seguir, uma análise das relações de confiança para cada role:

-   **`plooral-ecs-task-role`**:
    -   **Quem pode assumir?** O serviço ECS Tasks (`ecs-tasks.amazonaws.com`).
    -   **Está correto?** Sim, esta é a configuração padrão e correta para uma role de tarefa ECS.
    -   **Riscos:** Nenhum risco inerente a esta relação de confiança.
    -   **Melhorias:** Nenhuma melhoria necessária.

-   **`plooral-ecs-execution-role`**:
    -   **Quem pode assumir?** O serviço ECS Tasks (`ecs-tasks.amazonaws.com`).
    -   **Está correto?** Sim, esta é a configuração padrão e correta para uma role de execução de tarefa ECS.
    -   **Riscos:** Nenhum risco inerente a esta relação de confiança.
    -   **Melhorias:** Nenhuma melhoria necessária.

-   **`plooral-lambda-execution-role`**:
    -   **Quem pode assumir?** O serviço Lambda (`lambda.amazonaws.com`).
    -   **Está correto?** Sim, esta é a configuração padrão e correta para uma role de execução do Lambda.
    -   **Riscos:** Nenhum risco inerente a esta relação de confiança.
    -   **Melhorias:** Nenhuma melhoria necessária.

-   **`plooral-codepipeline-role`**:
    -   **Quem pode assumir?** O serviço CodePipeline (`codepipeline.amazonaws.com`).
    -   **Está correto?** Sim, esta é a configuração correta para uma role de serviço do CodePipeline.
    -   **Riscos:** Nenhum risco inerente a esta relação de confiança.
    -   **Melhorias:** Nenhuma melhoria necessária.

-   **`plooral-codebuild-role`**:
    -   **Quem pode assumir?** O serviço CodeBuild (`codebuild.amazonaws.com`) e qualquer entidade principal na organização `o-exampleorgid`.
    -   **Está correto?** A parte do CodeBuild está correta. A parte da organização é um **risco de segurança**.
    -   **Riscos:** Permitir que qualquer entidade principal na organização assuma essa role é muito permissivo. Se uma credencial de um usuário ou serviço menos privilegiado for comprometida, ela poderá ser usada para assumir essa role e obter os privilégios do CodeBuild.
    -   **Melhorias:** Restringir a entidade principal a uma role específica ou a um conjunto de usuários que realmente precisam assumir essa role. Se o objetivo é permitir que outras contas da organização acessem, a melhor prática é especificar o ARN da role da outra conta na política de confiança.

-   **`plooral-developer-role`**:
    -   **Quem pode assumir?** Qualquer entidade principal da AWS que tenha a autenticação multifator (MFA) ativada.
    -   **Está correto?** **Não, isso é um risco de segurança crítico.**
    -   **Riscos:** Esta política permite que *qualquer* usuário ou role em *qualquer* conta da AWS assuma essa role, desde que a sessão tenha sido autenticada com MFA. Um ator mal-intencionado pode facilmente satisfazer essa condição em sua própria conta da AWS e, em seguida, assumir a `plooral-developer-role`.
    -   **Melhorias:** A entidade principal deve ser restrita a uma Unidade Organizacional (OU) específica, a um grupo de usuários ou a uma lista de ARNs de usuários conhecidos. Por exemplo, poderia ser restrito a `arn:aws:iam::123456789012:root` para permitir que apenas usuários nesta conta assumam a role.

-   **`plooral-admin-role`**:
    -   **Quem pode assumir?** A conta root `123456789012`.
    -   **Está correto?** Sim, isso permite que qualquer usuário IAM na conta `123456789012` (com as permissões apropriadas de `sts:AssumeRole`) assuma essa role.
    -   **Riscos:** O risco é gerenciado pelas permissões dos usuários IAM que podem assumir a role. Se um usuário com permissões excessivas for comprometido, ele poderá assumir a role de administrador.
    -   **Melhorias:** Nenhuma melhoria necessária na política de confiança em si, mas é crucial garantir que apenas os usuários que precisam de privilégios de administrador tenham a permissão `sts:AssumeRole` para esta role.

-   **`plooral-eventbridge-role`**:
    -   **Quem pode assumir?** O serviço EventBridge (`events.amazonaws.com`).
    -   **Está correto?** Sim, e a condição `aws:SourceArn` restringe o acesso apenas a regras do EventBridge que começam com `plooral-`, o que é uma boa prática de segurança.
    -   **Riscos:** Nenhum risco inerente a esta relação de confiança.
    -   **Melhorias:** Nenhuma melhoria necessária.

### 4.3 WAF Improvements

> What WAF rule changes do you recommend?

A configuração atual do WAF está bloqueando tráfego legítimo da região da Ásia-Pacífico, provavelmente devido a regras de bloqueio geográfico excessivamente amplas. Além disso, existem regras personalizadas que são redundantes em relação aos conjuntos de regras gerenciadas pela AWS.

As seguintes alterações são recomendadas para melhorar o WAF, reduzir falsos positivos e manter a segurança:

-   **Modificar a regra de bloqueio geográfico (`plooral-geo-block-rule`):**
    -   **Problema:** A regra atual bloqueia a China (CN), um país com um grande volume de tráfego legítimo na Ásia-Pacífico. Isso é a causa mais provável do bloqueio de tráfego legítimo.
    -   **Recomendação:** Em vez de bloquear países inteiros, a abordagem deve ser mais direcionada.
        -   **Alternativa 1 (Preferencial):** Substitua a regra de bloqueio geográfico pela regra gerenciada `AWSManagedRulesAnonymousIpList`. Esta regra bloqueia endereços IP de fontes anônimas conhecidas (como nós de saída do Tor, proxies, etc.), que são frequentemente usadas para tráfego malicioso.
        -   **Alternativa 2:** Se o bloqueio geográfico for um requisito, use a ação `Count` em vez de `Block` para a regra `plooral-geo-block-rule`. Isso permitirá a análise dos logs do WAF para identificar quais endereços IP estão sendo bloqueados e se são de fato maliciosos antes de aplicar um bloqueio. A regra também pode ser refinada para bloquear apenas regiões específicas conhecidas por originar ataques, em vez de países inteiros.

-   **Remover regras personalizadas redundantes (`plooral-sql-injection-rule` e `plooral-xss-rule`):**
    -   **Problema:** As regras personalizadas para SQL Injection e Cross-Site Scripting são redundantes, pois o conjunto de regras gerenciadas `AWSManagedRulesCommonRuleSet` já oferece proteção contra esses tipos de ataques (e muitos outros).
    -   **Recomendação:** Remova as regras `plooral-sql-injection-rule` e `plooral-xss-rule`. Isso simplifica a configuração, reduz a chance de falsos positivos e diminui a contagem de WCU (Web ACL Capacity Units).

-   **Ajustar a regra de limite de taxa (`plooral-rate-limit-rule`):**
    -   **Problema:** O limite de 2.000 solicitações a cada 5 minutos por IP pode ser muito baixo para usuários legítimos que estão atrás de um NAT corporativo ou de operadoras de celular, que compartilham o mesmo endereço IP.
    -   **Recomendação:** Monitore os logs do WAF para verificar se IPs legítimos estão sendo bloqueados por esta regra. Se estiverem, considere aumentar o limite. Para uma mitigação mais sofisticada, a chave de agregação da regra de limite de taxa pode ser alterada para usar um cabeçalho HTTP, como o `X-Forwarded-For`, se a aplicação estiver atrás de um proxy que o insira.

-   **Ordem de Prioridade das Regras:**
    -   A ordem de prioridade atual está razoável, com as regras gerenciadas sendo executadas primeiro. Após as alterações, a nova ordem de prioridade deve ser:
        1.  `AWSManagedRulesCommonRuleSet`
        2.  `AWSManagedRulesKnownBadInputsRuleSet`
        3.  `AWSManagedRulesAnonymousIpList` (se usada)
        4.  `plooral-rate-limit-rule`
        5.  Regras personalizadas adicionais (se houver)
        6.  `plooral-geo-block-rule` (em modo `Count`, se mantida)

Ao aplicar essas alterações, é fundamental usar o modo `Count` para todas as novas regras ou regras modificadas. Isso permite a validação do comportamento da regra em um ambiente de produção sem impactar o tráfego legítimo. Após um período de monitoramento e análise dos logs, as regras podem ser alteradas para a ação `Block` com maior confiança.

### 4.4 SSM Parameter Security

> How should the SSM parameters be secured?

A configuração atual dos parâmetros no SSM (Systems Manager Parameter Store) apresenta várias vulnerabilidades que precisam ser corrigidas. A seguir, uma análise dos problemas e as recomendações para aumentar a segurança.

**Problemas Identificados:**

1.  **Dados Sensíveis Armazenados como Texto Plano (`String`):**
    -   Os parâmetros `/plooral/prod/api-keys/stripe`, `/plooral/prod/api-keys/sendgrid`, e `/plooral/prod/db-connection-string` contêm informações altamente sensíveis (chaves de API e senhas de banco de dados) e estão armazenados como `String`, ou seja, em texto plano. Qualquer usuário ou serviço com a permissão `ssm:GetParameter` pode ler esses segredos.
    -   O parâmetro de desenvolvimento `/plooral/dev/db-password` também está como `String`. Embora seja um ambiente de desenvolvimento, a prática de armazenar segredos em texto plano deve ser evitada.

2.  **Uso da Chave KMS Padrão (`alias/aws/ssm`):**
    -   Os parâmetros que são `SecureString` (`/plooral/prod/db-password` e `/plooral/prod/jwt-secret`) estão usando a chave KMS gerenciada pela AWS (`alias/aws/ssm`). Embora isso forneça criptografia, o uso de uma chave gerenciada pelo cliente (CMK - Customer-Managed Key) oferece um controle muito mais granular sobre o acesso e as políticas de rotação.

3.  **Hierarquia de Parâmetros Inconsistente:**
    -   A hierarquia `/plooral/[ambiente]/[serviço]/[nome]` é uma boa prática, mas há parâmetros de produção e desenvolvimento misturados no mesmo nível, o que pode levar a erros de configuração e acesso indevido.

4.  **Ausência de Estratégia de Rotação de Segredos:**
    -   Não há indicação de uma estratégia de rotação para os segredos, como a senha do banco de dados ou as chaves de API. Segredos estáticos e de longa duração aumentam o risco de comprometimento.

**Recomendações de Segurança:**

1.  **Converter Parâmetros para `SecureString`:**
    -   Todos os parâmetros que contêm dados sensíveis devem ser do tipo `SecureString`. Isso inclui:
        -   `/plooral/prod/api-keys/stripe`
        -   `/plooral/prod/api-keys/sendgrid`
        -   `/plooral/prod/db-connection-string`
        -   `/plooral/dev/db-password`
    -   A conversão para `SecureString` garante que esses parâmetros sejam criptografados em repouso.

2.  **Utilizar uma Chave KMS Gerenciada pelo Cliente (CMK):**
    -   Crie uma nova chave KMS dedicada para o Plooral (ex: `alias/plooral-kms-key`).
    -   Use essa CMK para criptografar todos os parâmetros `SecureString`.
    -   A política da CMK deve ser configurada para permitir o acesso de `kms:Decrypt` apenas para as roles IAM que precisam ler os segredos. Isso adiciona uma camada extra de controle de acesso, pois um invasor precisaria de permissões tanto para o SSM quanto para o KMS.

3.  **Refinar as Políticas de Acesso do IAM:**
    -   As políticas IAM (analisadas na Pergunta 4.1) devem ser corrigidas para conceder acesso de leitura (`ssm:GetParameter*`) apenas aos caminhos de parâmetros específicos que cada serviço precisa.
    -   A permissão `kms:Decrypt` também deve ser limitada à CMK do Plooral.

4.  **Implementar uma Estratégia de Rotação de Segredos:**
    -   **Para a senha do banco de dados:** A melhor prática é mover a senha do banco de dados do Parameter Store para o **AWS Secrets Manager**. O Secrets Manager oferece rotação automática de senhas para serviços como o RDS, o que pode ser feito sem tempo de inatividade para a aplicação.
    -   **Para chaves de API:** Para chaves de API como Stripe e SendGrid, defina um ciclo de vida para a rotação manual ou, se as APIs dos provedores permitirem, crie uma função Lambda para automatizar a rotação.

5.  **Organizar a Hierarquia de Parâmetros:**
    -   Mantenha uma hierarquia estrita e consistente. Todos os parâmetros de produção devem estar sob `/plooral/prod/` e os de desenvolvimento sob `/plooral/dev/`. Isso ajuda a evitar o uso acidental de parâmetros de produção em ambientes de desenvolvimento e vice-versa.

### 4.5 CloudFront Configuration Review

> Review the CloudFront config. What issues or improvements do you see?

A revisão da configuração da distribuição do CloudFront revelou várias falhas de segurança e oportunidades de melhoria. A seguir, os problemas identificados e as recomendações para fortalecer a segurança e a performance.

**Problemas Identificados:**

1.  **Origem S3 Insegura:**
    -   A origem `s3-static-origin` não está usando uma identidade de acesso à origem (`OriginAccessIdentity` está vazio). Isso significa que o bucket S3 correspondente provavelmente está configurado para acesso público, permitindo que qualquer pessoa acesse os arquivos diretamente, contornando o CloudFront e o WAF.

2.  **Protocolos TLS de Origem Desatualizados:**
    -   A origem `alb-origin` está configurada para aceitar `TLSv1.1`, que é um protocolo antigo e com vulnerabilidades conhecidas.

3.  **Ausência de Cabeçalhos de Segurança:**
    -   O `DefaultCacheBehavior` não tem uma `ResponseHeadersPolicyId` associada. Isso significa que a distribuição não está enviando cabeçalhos de segurança importantes para o navegador do cliente, como `Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, e `X-XSS-Protection`.

4.  **Logging de Acesso Desabilitado:**
    -   O logging de acesso para a distribuição está desabilitado (`"Enabled": false`). Isso é uma falha grave de segurança e operacional, pois não há registros das solicitações atendidas pelo CloudFront, o que impede a análise de segurança, a detecção de anomalias e a solução de problemas.

5.  **Price Class Restritiva:**
    -   A `PriceClass` está configurada como `PriceClass_100` (América do Norte e Europa). Dado que a empresa está enfrentando problemas com tráfego da Ásia-Pacífico, essa configuração pode estar contribuindo para uma maior latência para usuários nessa região.

**Recomendações de Melhoria:**

1.  **Proteger a Origem S3 com Origin Access Control (OAC):**
    -   Configure um **Origin Access Control (OAC)** para a origem `s3-static-origin`. O OAC é a abordagem mais recente e flexível para restringir o acesso a buckets S3 a partir do CloudFront.
    -   Após criar o OAC, atualize a política do bucket S3 para permitir o acesso `s3:GetObject` apenas para a identidade de serviço do CloudFront associada ao OAC. Remova qualquer permissão de acesso público do bucket.

2.  **Atualizar a Política de TLS da Origem:**
    -   Altere a configuração `OriginSslProtocols` para a origem `alb-origin` para aceitar apenas `TLSv1.2`. Isso garante que a comunicação entre o CloudFront e o Application Load Balancer seja sempre criptografada com um protocolo seguro.

3.  **Implementar uma Política de Cabeçalhos de Resposta (Response Headers Policy):**
    -   Crie uma nova `ResponseHeadersPolicy` que adicione os seguintes cabeçalhos de segurança:
        -   **`Strict-Transport-Security`:** Força o navegador a se comunicar apenas via HTTPS. Ex: `max-age=31536000; includeSubDomains; preload`
        -   **`Content-Security-Policy`:** Ajuda a prevenir ataques de XSS, definindo as fontes de conteúdo permitidas. Ex: `default-src 'self';`
        -   **`X-Content-Type-Options`:** Previne que o navegador tente adivinhar o tipo de conteúdo (`nosniff`).
        -   **`X-Frame-Options`:** Protege contra ataques de clickjacking, impedindo que o site seja renderizado em um `<iframe>`. Ex: `SAMEORIGIN`
        -   **`X-XSS-Protection`:** Habilita o filtro de XSS nos navegadores que o suportam. Ex: `1; mode=block`
    -   Associe essa nova política ao `DefaultCacheBehavior`.

4.  **Habilitar o Logging de Acesso:**
    -   Habilite o logging de acesso para a distribuição do CloudFront.
    -   Crie um bucket S3 dedicado e seguro para armazenar os logs de acesso.
    -   Aponte o logging para esse bucket. Os logs são essenciais para monitoramento de segurança, auditoria e análise de tráfego.

5.  **Revisar a Price Class:**
    -   Considere alterar a `PriceClass` para `PriceClass_200` (inclui a Ásia) ou `PriceClass_All` para melhorar a performance e a disponibilidade para usuários na região da Ásia-Pacífico. A escolha dependerá da base de usuários global da aplicação e do custo.

6.  **Habilitar o HTTP/3:**
    -   A configuração atual usa `http2`. Se a maioria dos clientes usar navegadores modernos, habilitar o `http3` pode oferecer melhorias de performance, especialmente em redes com perda de pacotes.

---

## Scenario 5 — Runbook and Onboarding

### 5.1 Runbook Created

> Confirm you created `answer-template/RUNBOOK.md`

- [X] RUNBOOK.md created and complete

### 5.2 Onboarding Plan Created

> Confirm you created `answer-template/ONBOARDING_30_DAYS.md`

- [X] ONBOARDING_30_DAYS.md created and complete

---

## Summary Sections

### Alarm Interpretation Summary

> Summarize your understanding of the CloudWatch alarms across all scenarios.

| Alarm | Purpose | Threshold | Response Action |
|-------|---------|-----------|-----------------|
| | | | |

### IAM & Security Decisions

> Summarize your security-related decisions and reasoning.

```
Your answer here
```

### 30-Day Onboarding Plan Overview

> Brief overview of your onboarding plan (details in ONBOARDING_30_DAYS.md).

**Week 1:**
- 

**Week 2:**
- 

**Week 3:**
- 

**Week 4:**
- 

### Risks & Mitigations

> What ongoing risks do you see in this environment?

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| | | | |

### Optional Improvements

> If you had more time, what would you improve?

1. 
2. 
3. 

---

## Final Checklist

Before submitting your work, verify:

- [ ] All scenario questions answered
- [ ] Corrected configs committed
- [ ] RUNBOOK.md created
- [ ] ONBOARDING_30_DAYS.md created
- [ ] Assumptions documented
- [ ] Reasoning is explicit throughout
- [ ] Repository is accessible and ready to share

