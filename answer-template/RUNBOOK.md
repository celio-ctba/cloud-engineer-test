# Runbook Operacional da Plataforma Plooral

Este documento serve como um guia operacional abrangente para a plataforma Plooral, visando garantir operações seguras, consistentes e eficientes.

## 1. Playbooks de Resposta a Incidentes

### 1.1 Resposta a Incidente P0 (Indisponibilidade Completa)
*   **Definição:** Indisponibilidade total do serviço crítico, afetando todos os usuários. Impacto financeiro e/ou reputacional severo.
*   **Objetivo:** Restaurar o serviço o mais rápido possível e minimizar o impacto.
*   **Procedimento:**
    1.  **Detecção:**
        *   Confirmação via alarmes do CloudWatch (ex: `PlooralAPIHighErrorRate`, `PlooralWorkerFailure`, `AuroraCPUCritical`).
        *   Relatos diretos de usuários ou monitoramento externo.
    2.  **Notificação Inicial (3 minutos):**
        *   Acionar o playbook P0 via webhook para o canal `#prod-alerts` no Slack.
        *   Notificar `eng-manager@plooral.com` e `platform-lead@plooral.com`.
        *   Criar sala de crise no Slack (ex: `#incidente-p0-AAAA-MM-DD-HHMM`).
        *   Iniciar ponte de conferência (videoconferência preferencialmente).
    3.  **Investigação Rápida (10 minutos):**
        *   Verificar o painel de status do CloudWatch para identificar o componente afetado.
        *   Analisar logs recentes no CloudWatch Logs para o serviço (`/ecs/plooral-api`, `/aws/lambda/plooral-worker`).
        *   Checar status do banco de dados Aurora (conexões, CPU, replicação).
        *   Confirmar status de serviços AWS na região (status.aws.amazon.com).
    4.  **Ação de Contenção (15-30 minutos):**
        *   **API (ECS Fargate):**
            *   Reiniciar tarefas do ECS: `aws ecs update-service --cluster plooral-cluster --service plooral-api-service --force-new-deployment`.
            *   Escalar horizontalmente o serviço (aumentar `desiredCount`): `aws ecs update-service --cluster plooral-cluster --service plooral-api-service --desired-count X`.
            *   Considerar rollback da última implantação (se houver suspeita): `aws codepipeline start-pipeline-execution --name plooral-api-pipeline --client-request-token <token-da-ultima-execucao-bem-sucedida>`.
        *   **Worker (Lambda):**
            *   Verificar erros nos logs da função Lambda.
            *   Desabilitar/pausar triggers SQS/SNS/EventBridge se o worker estiver causando um efeito em cascata.
            *   Reverter para versão anterior da função Lambda.
        *   **Banco de Dados (Aurora PostgreSQL):**
            *   Verificar logs de erro do Aurora.
            *   Confirmar failover para instância de réplica (se aplicável e automático).
            *   Reiniciar a instância de escritor (último recurso).
        *   **CloudFront/WAF:**
            *   Invalidar cache do CloudFront para `/*`: `aws cloudfront create-invalidation --distribution-id <ID_DISTRIBUICAO> --paths "/*"`.
            *   Verificar regras do WAF para bloqueios indevidos.
    5.  **Comunicação (15 minutos após contenção):**
        *   Enviar atualização para `#prod-alerts` e `eng-manager@plooral.com`, `platform-lead@plooral.com`.
        *   Preparar e enviar comunicado externo se necessário (via template).
    6.  **Verificação e Monitoramento:**
        *   Monitorar de perto os serviços afetados, métricas e logs.
        *   Confirmar a estabilização do serviço.
    7.  **Resolução:**
        *   Quando o serviço estiver totalmente restaurado e estável, declarar o incidente como resolvido.
        *   Enviar comunicação final interna e externa.

### 1.2 Resposta a Incidente P1 (Serviço Degradado)
*   **Definição:** Serviço operando com performance reduzida ou funcionalidade limitada, afetando um subconjunto de usuários ou uma funcionalidade chave.
*   **Objetivo:** Restaurar a performance total e minimizar o impacto contínuo.
*   **Procedimento:**
    1.  **Detecção:** Alarmes do CloudWatch (ex: `PlooralAPILatencyHigh`, `SQSQueueOldestMessageAge`), relatos de usuários.
    2.  **Notificação Inicial (5 minutos):**
        *   Acionar playbook P1 via webhook para `#prod-alerts`.
        *   Notificar `platform-lead@plooral.com`.
        *   Criar sala de crise no Slack (ex: `#incidente-p1-AAAA-MM-DD-HHMM`).
    3.  **Investigação (15 minutos):**
        *   Utilizar painéis de CloudWatch, logs e métricas específicas do componente afetado.
        *   Focar em identificar a causa raiz da degradação.
    4.  **Ação de Contenção/Mitigação (30-60 minutos):**
        *   **API (ECS Fargate):**
            *   Escalar serviço (se CPU/Memória estiverem altos).
            *   Reiniciar tarefas problemáticas.
        *   **Worker (Lambda):**
            *   Ajustar configurações de simultaneidade.
            *   Verificar limites de taxa de APIs externas.
        *   **Aurora:**
            *   Identificar e otimizar queries lentas.
            *   Escalar instâncias de leitura.
        *   **SQS:**
            *   Aumentar número de consumidores.
            *   Ajustar Visibility Timeout.
        *   **CloudFront/WAF:**
            *   Reverificar configurações de cache e WAF.
    5.  **Comunicação (30 minutos após contenção):** Atualizações regulares para `#prod-alerts`.
    6.  **Verificação e Resolução:** Monitorar melhoria nas métricas. Declarar resolução quando a performance normal for restaurada.

### 1.3 Resposta a Incidente P2 (Problema Não Crítico)
*   **Definição:** Pequeno problema que não afeta diretamente a disponibilidade ou funcionalidade crítica para o usuário final, mas requer atenção.
*   **Objetivo:** Resolver o problema sem urgência imediata.
*   **Procedimento:**
    1.  **Detecção:** Alarmes do CloudWatch (ex: `PlooralAPIRecoverableErrors`), monitoramento de logs, relatórios internos.
    2.  **Notificação Inicial (15 minutos):** Notificação via webhook para `#prod-alerts`. Não exige criação imediata de sala de crise.
    3.  **Investigação (tempo flexível):** Análise detalhada da causa raiz.
    4.  **Ação de Resolução:** Implementar correção em ciclo de desenvolvimento normal (hotfix, próxima release).
    5.  **Comunicação:** Atualização no canal `#prod-alerts` quando resolvido.

### 1.4 Matriz de Escalonamento
| Tipo de Incidente | Após | Para Quem Escalar | Contato | Notas |
|-------------------|------|-------------------|---------|-------|
| P0/P1 - Sem progresso | 30 min | Platform Lead | `platform-lead@plooral.com` | Suporte técnico avançado. |
| P0/P1 - Impacto de Negócio | 60 min | Engineering Manager | `eng-manager@plooral.com` | Decisões sobre impacto de negócio e comunicação externa. |
| P0/P1 - Problema de Segurança | Imediato | Security Team | `security@plooral.com` | Para qualquer suspeita ou confirmação de falha de segurança. |
| P0/P1 - Problemas persistentes na AWS | 2h | AWS TAM | `aws-tam@plooral.com` | Para engajamento com suporte AWS. |
| P0/P1 - Problemas com Slack/Alertas | Imediato | Slack Admin | `slack-admin@plooral.com` | Se houver falha na entrega de alertas ou problemas no Slack. |

### 1.5 Templates de Comunicação
*   **Interna (Canal Slack `#prod-alerts`):**
    *   **Início do Incidente:** `[INCIDENTE P<N>] Título Breve. Status: Investigando. Impacto: <Breve Descrição do Impacto>. Equipe: @on-call.`
    *   **Atualização (a cada 30-60 min):** `[INCIDENTE P<N>] Título Breve. Status: <Investigando/Contendo/Mitigando/Resolvido>. Última Atualização: <O que foi feito>. Próximos Passos: <O que será feito>.`
    *   **Resolução:** `[INCIDENTE P<N>] Título Breve. Status: RESOLVIDO. Duração: <Tempo Total>. Causa Raiz Inicial: <Breve Causa (se souber)>. Próximos Passos: Iniciar Post-Mortem.`
*   **Externa (Email/Status Page):**
    *   **Início (se necessário):** `Estamos cientes de problemas de serviço afetando <componente/funcionalidade>. Nossa equipe está investigando ativamente e fornecerá uma atualização em breve.`
    *   **Atualização:** `Identificamos a causa raiz e estamos trabalhando na implementação de uma correção. Esperamos resolver o problema em <X> minutos/horas.`
    *   **Resolução:** `O problema de serviço foi resolvido. Todos os sistemas estão operando normalmente. Pedimos desculpas por qualquer inconveniente.`

### 1.6 Processo de Revisão Pós-Incidente (Post-Mortem)
1.  **Reunião (24-48h após P0/P1):** Todos os envolvidos e partes interessadas.
2.  **Objetivo:** Entender o que aconteceu, por que aconteceu, o que foi bem, o que não foi bem e como prevenir recorrências. Não é uma caça às bruxas.
3.  **Documentação:** Criar documento de Post-Mortem contendo:
    *   Linha do Tempo Detalhada.
    *   Causa Raiz.
    *   Impacto.
    *   Ações Tomadas (contenção, mitigação, resolução).
    *   Oportunidades de Melhoria (processo, monitoramento, código, infraestrutura).
    *   Itens de Ação com Responsável e Prazo.
4.  **Ações:** Garantir que os itens de ação sejam acompanhados e implementados.

## 2. Procedimentos de Implantação

### 2.1 Checklist Pré-Implantação
*   [ ] O código foi revisado e aprovado?
*   [ ] Os testes unitários e de integração foram executados e passaram?
*   [ ] As métricas de cobertura de testes estão dentro do limite aceitável?
*   [ ] Há alguma mudança de esquema de banco de dados? Se sim, a migração foi testada e é retrocompatível?
*   [ ] Novas variáveis de ambiente ou segredos foram configurados no SSM Parameter Store?
*   [ ] Novas dependências ou bibliotecas foram adicionadas?
*   [ ] Há alterações que impactam APIs externas ou integrações?
*   [ ] A documentação (interna/externa) foi atualizada para refletir as mudanças?
*   [ ] As permissões IAM foram revisadas (se houver alteração)?
*   [ ] O impacto potencial da implantação foi comunicado às partes interessadas (se relevante)?
*   [ ] Há uma janela de manutenção ou freeze de implantação ativo?
*   [ ] O pipeline de CI/CD está verde na branch `main`?
*   [ ] Foi definido um plano de rollback claro e testável?

### 2.2 Etapas de Implantação em Produção
A implantação é realizada via AWS CodePipeline.
1.  **Garantir o Checklist Pré-Implantação:** Todos os itens devem estar marcados.
2.  **Iniciar Implantação:**
    *   Para API (ECS Fargate): Merge da feature branch para `main`. Isso acionará o pipeline `plooral-api-pipeline`.
    *   Para Worker (Lambda): Merge da feature branch para `main`. Isso acionará o pipeline `plooral-worker-pipeline`.
3.  **Monitorar o Pipeline:** Acompanhar o progresso do CodePipeline no console da AWS.
4.  **Verificar Status do Serviço:**
    *   Para ECS: Monitorar o `desiredCount` e `runningTasks` no console do ECS.
    *   Para Lambda: Monitorar as métricas `Invocations`, `Errors` e `Duration` no CloudWatch.
5.  **Executar Verificação Pós-Implantação:** (Ver seção 2.3)

### 2.3 Verificação Pós-Implantação
*   [ ] **Monitoramento de Saúde:** Verificar o painel de CloudWatch para quaisquer alarmes acionados ou degradação de métricas (CPU, Memória, Latência, Erros).
*   [ ] **Logs:** Analisar os logs recentes no CloudWatch Logs para o serviço implantado (`/ecs/plooral-api`, `/aws/lambda/plooral-worker`) em busca de erros ou anomalias.
*   [ ] **Teste de Sanidade:** Executar smoke tests ou testes de ponta a ponta em ambientes de produção (se automatizado). Caso contrário, realizar um teste manual rápido das funcionalidades críticas.
*   [ ] **Funcionalidade:** Confirmar que as novas funcionalidades estão disponíveis e funcionando conforme o esperado.
*   [ ] **Métricas de Negócio:** Verificar se não houve impacto negativo nas métricas de negócio (se aplicável).
*   [ ] **SQS:** Monitorar `ApproximateNumberOfMessagesVisible` e `ApproximateNumberOfMessagesNotVisible` para garantir processamento normal.
*   [ ] **CloudFront:** Realizar invalidação de cache se as alterações exigirem a atualização imediata dos ativos em cache.

### 2.4 Procedimento de Rollback (Passo a Passo)
**Objetivo:** Reverter uma implantação problemática para a última versão estável.
1.  **Identificar a Versão Estável:** Consultar o histórico do CodePipeline para a última execução bem-sucedida. Anotar o `ClientRequestToken` ou o commit SHA.
2.  **Iniciar Rollback:**
    *   **Para API (ECS Fargate):**
        *   No console do CodePipeline, selecione o pipeline `plooral-api-pipeline`.
        *   Clique em "Release change" e, no menu suspenso, selecione a revisão de código da última implantação bem-sucedida.
        *   Ou via CLI: `aws codepipeline start-pipeline-execution --name plooral-api-pipeline --client-request-token <token-da-ultima-execucao-bem-sucedida>`.
    *   **Para Worker (Lambda):**
        *   No console do Lambda, selecione a função `plooral-worker`.
        *   Vá em "Versions", selecione a última versão estável.
        *   Vá em "Aliases", edite o alias `LIVE` para apontar para a versão estável.
        *   Ou via CLI: `aws lambda update-alias --function-name plooral-worker --name LIVE --function-version <numero-da-versao-estavel>`.
3.  **Monitorar o Rollback:** Acompanhar o progresso da implantação revertida.
4.  **Verificar Pós-Rollback:** Repetir as etapas de "Verificação Pós-Implantação" (Seção 2.3) para garantir que o serviço foi restaurado para um estado funcional.
5.  **Comunicação:** Informar a equipe no `#prod-alerts` sobre o rollback e o motivo.

### 2.5 Processo de Implantação de Hotfix
1.  **Criar Branch de Hotfix:** A partir da branch `main`, criar uma nova branch (ex: `hotfix/nome-do-hotfix`).
2.  **Implementar Correção:** Desenvolver a correção na branch de hotfix.
3.  **Revisão de Código:** Solicitar revisão de código urgente.
4.  **Testes:** Executar testes unitários e de integração. Considerar testes em ambiente de staging.
5.  **Merge para Main:** Fazer merge da branch de hotfix para `main`. Isso acionará o pipeline de CI/CD.
6.  **Monitoramento e Verificação:** Monitorar a implantação e executar a verificação pós-implantação conforme a Seção 2.3.
7.  **Comunicação:** Comunicar a implantação do hotfix para as partes interessadas.

### 2.6 Política de Congelamento de Implantação (Deployment Freeze Policy)
*   **Períodos:** Congelamentos de implantação serão anunciados para períodos de pico (ex: Black Friday, feriados prolongados) ou eventos específicos da empresa.
*   **Duração:** A duração e as exceções serão comunicadas com antecedência pelo Engineering Manager.
*   **Exceções:** Somente hotfixes críticos P0/P1, aprovados pelo Engineering Manager e Platform Lead, podem ser implantados durante um freeze.

## 3. Guias de Troubleshooting

### 3.1 Troubleshooting de Serviço ECS (Fargate)

#### 3.1.1 Serviço Não Iniciando
*   **Sintoma:** `desiredCount` > `runningTasks`, nenhuma tarefa inicia ou fica em `PENDING` por muito tempo.
*   **Ações:**
    1.  **Logs do Scheduler:** Verificar eventos do serviço ECS no console para mensagens de erro (ex: `unable to place a task`).
    2.  **Logs da Tarefa:** Inspecionar os logs da tarefa no CloudWatch Logs (`/ecs/plooral-api`). Procurar por erros de inicialização (`Container exited unexpectedly`).
    3.  **Configuração da Tarefa:**
        *   Verificar a `task definition`: imagem Docker correta, portas mapeadas, variáveis de ambiente.
        *   Confirmar que `CPU` e `Memory` são suficientes e estão dentro dos limites do Fargate.
        *   Validar roles IAM (`taskRole`, `executionRole`) – permissões para ECR, CloudWatch Logs, SSM Parameter Store.
    4.  **Rede:** Verificar grupos de segurança (portas abertas para ALBs e outras tarefas), sub-redes (capacidade de IPs).
    5.  **Secrets:** Se estiver usando SSM Parameter Store, verificar se os parâmetros existem e se a `taskRole` tem permissão para acessá-los.

#### 3.1.2 Tarefas Falhando em Health Checks
*   **Sintoma:** Load Balancer marca tarefas como `unhealthy`, causando reinícios ou remoção do target group.
*   **Ações:**
    1.  **Configuração do Health Check:**
        *   No Target Group do ALB, verificar a porta, caminho (`/health`), códigos de sucesso (ex: `200-299`), e thresholds.
        *   Verificar se a aplicação tem um endpoint de `/health` e se ele retorna o código HTTP esperado.
    2.  **Logs da Aplicação:** Inspecionar logs da tarefa no CloudWatch Logs (`/ecs/plooral-api`) no período das falhas para ver erros internos ou timeouts na aplicação.
    3.  **Recursos:** Tarefas podem estar sob pressão de CPU/Memória, impedindo a resposta ao health check.

#### 3.1.3 Erros de OOM (Out Of Memory) no Container
*   **Sintoma:** Tarefas ECS são encerradas com `SIGKILL` ou `Exit Code 137`, geralmente acompanhado de mensagens de OOM nos logs do Docker (visíveis via `aws logs get-log-events`).
*   **Ações:**
    1.  **Aumentar Memória:** Aumentar o limite de `memory` na `task definition` do ECS.
    2.  **Analisar Uso:** Usar métricas do CloudWatch para `MemoryUtilization` para entender o padrão de uso.
    3.  **Otimizar Aplicação:** Identificar vazamentos de memória ou padrões de alto consumo na aplicação Node.js.
    4.  **Coleta de Lixo:** Ajustar configurações do coletor de lixo do Node.js (ex: `--max-old-space-size`).

#### 3.1.4 Implantação Travada em Progresso
*   **Sintoma:** Nova implantação não finaliza, tarefas antigas e novas permanecem ativas, ou o serviço não alcança o `desiredCount` da nova versão.
*   **Ações:**
    1.  **Eventos do Serviço ECS:** Verificar mensagens de erro ou avisos.
    2.  **Health Checks:** Se as novas tarefas estão falhando nos health checks, verificar Seção 3.1.2.
    3.  **Capacidade:** Confirmar que há capacidade de rede (IPs) e recursos de CPU/Memória suficientes para as novas tarefas e as antigas (durante a transição).
    4.  **Rollback:** Se o problema persistir, iniciar um rollback para a versão anterior.

#### 3.1.5 Problemas de Escalabilidade
*   **Sintoma:** Aumentos de tráfego não resultam em mais tarefas, ou o serviço permanece com baixa performance mesmo com auto-scaling ativado.
*   **Ações:**
    1.  **Políticas de Auto Scaling:** Verificar configurações das políticas de auto scaling do serviço ECS (mínimo, máximo, métricas, thresholds de trigger, tempo de cooldown).
    2.  **Métricas:** Confirmar que as métricas de auto scaling (ex: `CPUUtilization`, `MemoryUtilization`, `ALBRequestCountPerTarget`) estão sendo coletadas e refletem a carga.
    3.  **Logs:** Procurar por erros nos logs da aplicação que possam estar impedindo a escalabilidade efetiva (ex: lentidão de DB).

### 3.2 Troubleshooting de Funções Lambda

#### 3.2.1 Timeouts da Função
*   **Sintoma:** Função Lambda excede o tempo configurado e é terminada.
*   **Ações:**
    1.  **Logs:** Verificar logs no CloudWatch Logs (`/aws/lambda/plooral-worker`) para identificar qual parte do código está demorando.
    2.  **Aumentar Timeout:** Aumentar temporariamente o `timeout` da função para permitir depuração.
    3.  **Otimizar Código:** Otimizar o código Python para reduzir o tempo de execução.
    4.  **Aumentar Memória:** A memória alocada à Lambda impacta diretamente a CPU. Aumentar a memória pode acelerar a execução.
    5.  **Dependências Externas:** Se a Lambda depende de APIs ou bancos de dados externos, verificar a latência desses serviços.

#### 3.2.2 Limites de Simultaneidade (Concurrency Limits)
*   **Sintoma:** Funções Lambda sendo rejeitadas com erro `TooManyRequestsException` ou `ThrottlingException`.
*   **Ações:**
    1.  **Monitoramento:** Verificar métrica `ConcurrentExecutions` no CloudWatch.
    2.  **Simultaneidade Reservada:** Se o pico de tráfego for esperado, configurar `Reserved Concurrency` para a função, garantindo que ela sempre tenha capacidade.
    3.  **Otimizar Triggers:** Reduzir a taxa de eventos do trigger (ex: SQS `BatchSize`, `BatchWindow`).
    4.  **Pedir Aumento de Cota:** Se a demanda for consistentemente alta, solicitar aumento de cotas de simultaneidade AWS.

#### 3.2.3 Erros de Permissão
*   **Sintoma:** Função Lambda falha ao acessar outros serviços AWS (Aurora, SQS, SSM) com erros `AccessDenied`.
*   **Ações:**
    1.  **Logs:** Mensagens `AccessDenied` serão visíveis nos logs do CloudWatch.
    2.  **Role de Execução:** Verificar a `executionRole` da função Lambda no console IAM.
    3.  **Políticas IAM:** Adicionar as permissões necessárias à política anexada à `executionRole` (ex: `sqs:SendMessage`, `rds:Connect`).
    4.  **Políticas de Recurso:** Em alguns casos (ex: S3, KMS), a política do próprio recurso também precisa permitir o acesso da Lambda.

#### 3.2.4 Otimização de Cold Start
*   **Sintoma:** Latência inicial elevada para invocações esporádicas da Lambda.
*   **Ações:**
    1.  **Aumentar Memória:** Mais memória geralmente resulta em CPUs mais potentes e cold starts mais rápidos.
    2.  **Otimizar Código:** Minimizar o número de módulos importados e o código de inicialização global.
    3.  **Provisioned Concurrency:** Para funções críticas de alta demanda, configurar `Provisioned Concurrency` para manter instâncias da Lambda "quentes".
    4.  **Layers:** Usar Lambda Layers para dependências comuns para reduzir o tamanho do pacote de deployment.

#### 3.2.5 Tratamento de DLQ (Dead-Letter Queue)
*   **Sintoma:** Mensagens se acumulando na DLQ configurada para a função Lambda ou SQS.
*   **Ações:**
    1.  **Monitorar DLQ:** Configurar alarmes no CloudWatch para `ApproximateNumberOfMessagesVisible` da DLQ.
    2.  **Logs:** Verificar os logs da função Lambda para as mensagens que foram enviadas para a DLQ. Identificar o erro que causou a falha de processamento.
    3.  **Causa Raiz:** O erro na DLQ pode indicar problemas no código da Lambda, dependências externas ou formato de mensagem inválido.
    4.  **Re-processar:** Após corrigir a causa raiz, re-processar as mensagens da DLQ (manualmente ou via script) de volta para a fila principal.

### 3.3 Troubleshooting de Aurora (PostgreSQL)

#### 3.3.1 Esgotamento de Conexões
*   **Sintoma:** Aplicação recebe erros `too many connections` ou `FATAL: remaining connection slots are reserved for non-replication superuser connections`.
*   **Ações:**
    1.  **Métricas:** Monitorar métrica `DatabaseConnections` no CloudWatch.
    2.  **Aumentar `max_connections`:** Modificar o grupo de parâmetros do Aurora para aumentar `max_connections` (requer reinício da instância).
    3.  **Otimizar Aplicação:**
        *   Garantir que a aplicação está fechando as conexões corretamente.
        *   Usar pool de conexões.
        *   Reduzir o número de conexões ociosas.
    4.  **Escalar Instância:** Aumentar o tipo de instância Aurora para uma com mais memória, que geralmente permite mais conexões.

#### 3.3.2 Queries Lentas
*   **Sintoma:** Latência alta em operações de banco de dados, aplicação lenta.
*   **Ações:**
    1.  **Logs de Queries Lentas:** Habilitar e analisar logs de queries lentas no Aurora.
    2.  **Performance Insights:** Utilizar AWS Performance Insights para identificar as queries mais demoradas, usuários, hosts, waits.
    3.  **Explain Plan:** Rodar `EXPLAIN ANALYZE` nas queries problemáticas para entender o plano de execução e identificar gargalos (índices ausentes, scans de tabela completa).
    4.  **Otimizar Índices:** Criar ou otimizar índices.
    5.  **Revisar Schema:** Desnormalização, particionamento.
    6.  **Escalar Instância:** Aumentar recursos de CPU/Memória para a instância de escritor ou adicionar réplicas de leitura.

#### 3.3.3 Atraso de Replicação (Replication Lag)
*   **Sintoma:** Dados escritos na instância de escritor não aparecem prontamente nas réplicas de leitura, causando inconsistências ou dados desatualizados para leituras.
*   **Ações:**
    1.  **Métrica:** Monitorar `AuroraReplicaLag` no CloudWatch.
    2.  **Carga na Escrita:** Alta carga na instância de escritor pode causar lag. Otimizar writes.
    3.  **Carga na Leitura (Réplica):** Queries longas ou ineficientes nas réplicas podem impactar a replicação.
    4.  **Escalar Instâncias:** Aumentar o tipo de instância da réplica e/ou do escritor.

#### 3.3.4 Problemas de Armazenamento
*   **Sintoma:** Banco de dados se aproxima do limite de armazenamento, ou performance degradada devido a I/O.
*   **Ações:**
    1.  **Métrica:** Monitorar `FreeStorageSpace` e `VolumeBytesUsed` no CloudWatch.
    2.  **Limpar Dados:** Arquivar ou apagar dados antigos não essenciais.
    3.  **Otimizar Schema:** Reduzir o tamanho de dados, otimizar tipos de dados.
    4.  **Aurora Scaling:** Aurora escala automaticamente o armazenamento, mas o uso excessivo pode indicar problemas de design ou retenção.
    5.  **Verificar I/O:** Monitorar métricas `DiskQueueDepth`, `ReadIOPS`, `WriteIOPS`, `ReadLatency`, `WriteLatency`.

#### 3.3.5 Tratamento de Failover
*   **Sintoma:** Interrupção do serviço devido a falha da instância de escritor, failover não ocorre ou demora.
*   **Ações:**
    1.  **Métricas:** Monitorar `FailoverCount` no CloudWatch.
    2.  **Logs de Eventos:** Verificar eventos do RDS para o cluster Aurora.
    3.  **DNS Caching:** Verificar se a aplicação está respeitando o TTL do DNS para o endpoint do cluster Aurora.
    4.  **Testar Failover:** Realizar testes de failover regularmente em ambiente de staging.
    5.  **Multi-AZ:** Confirmar que o cluster Aurora está configurado para Multi-AZ com pelo menos uma réplica em outra AZ para failover automático.

### 3.4 Troubleshooting de SQS

#### 3.4.1 Fila com Backlog
*   **Sintoma:** Número de mensagens visíveis (`ApproximateNumberOfMessagesVisible`) e/ou em atraso (`ApproximateNumberOfMessagesDelayed`) aumenta rapidamente.
*   **Ações:**
    1.  **Monitoramento:** Verificar métricas `ApproximateNumberOfMessagesVisible`, `ApproximateNumberOfMessagesNotVisible`, `NumberOfMessagesSent`, `NumberOfMessagesReceived`, `NumberOfMessagesDeleted`.
    2.  **Consumidores:** Verificar se os consumidores (funções Lambda Worker) estão processando as mensagens.
        *   Métricas `Invocations` e `Errors` da Lambda.
        *   Logs da Lambda para erros de processamento.
    3.  **Simultaneidade da Lambda:** Aumentar a simultaneidade reservada da Lambda ou ajustar o `BatchSize` e `BatchWindow` do trigger SQS.
    4.  **Produtores:** Verificar se a taxa de mensagens enviadas está muito alta para a capacidade de processamento.
    5.  **Dependências:** A lentidão na Lambda pode ser causada por dependências externas (DB, outras APIs).

#### 3.4.2 Acúmulo de DLQ (Dead-Letter Queue)
*   **Sintoma:** Mensagens se acumulam na DLQ associada à fila SQS principal.
*   **Ações:**
    1.  **Monitoramento:** Configurar alarmes para `ApproximateNumberOfMessagesVisible` da DLQ.
    2.  **Logs do Consumidor:** Analisar logs da função Lambda Worker para as mensagens que falharam e foram enviadas para a DLQ.
    3.  **Causa Raiz:** O erro pode ser no código do worker, problemas de permissão, formato de mensagem inválido, ou dependências externas.
    4.  **Re-processar:** Após corrigir a causa raiz, mover as mensagens da DLQ de volta para a fila principal (via CLI ou console).

#### 3.4.3 Falhas no Processamento de Mensagens
*   **Sintoma:** Mensagens sendo recebidas, mas não processadas com sucesso, frequentemente retornando à fila.
*   **Ações:**
    1.  **Logs do Consumidor:** Verificar logs detalhados da função Lambda Worker em busca de exceções ou erros lógicos.
    2.  **`Visibility Timeout`:** Se a função Lambda demora mais para processar do que o `Visibility Timeout` da fila, a mensagem pode ser processada várias vezes. Aumentar o `Visibility Timeout` da fila e/ou o `timeout` da Lambda.
    3.  **Idempotência:** Garantir que o processamento da mensagem é idempotente (pode ser executado várias vezes sem efeitos colaterais).
    4.  **Carga:** Verifique a utilização de CPU/Memória da Lambda.

#### 3.4.4 Problemas de `Visibility Timeout`
*   **Sintoma:** Mensagens são re-entregues antes de serem processadas ou deletadas, levando a processamento duplicado.
*   **Ações:**
    1.  **Ajustar `Visibility Timeout`:** No console SQS, aumentar o `Visibility Timeout` da fila para ser maior que o tempo máximo de execução do consumidor (função Lambda).
    2.  **Otimizar Consumidor:** Se o consumidor estiver demorando muito, otimizar seu código ou escalar seus recursos (memória na Lambda).

### 3.5 Troubleshooting de CloudFront / WAF

#### 3.5.1 Invalidação de Cache
*   **Sintoma:** Usuários veem conteúdo antigo mesmo após atualização da origem.
*   **Ações:**
    1.  **Criar Invalidação:** No console do CloudFront, criar uma invalidação para os caminhos afetados (ex: `/index.html`, `/assets/*`, ou `/*` para tudo).
    2.  **Verificar Status:** Monitorar o status da invalidação.
    3.  **TTL:** Verificar o `Default TTL` e `Maximum TTL` na política de cache do CloudFront e nos cabeçalhos `Cache-Control` da origem.
    4.  **Versão de Arquivo:** Utilizar cache busting (ex: `main.js?v=123` ou `main.<hash>.js`) para arquivos estáticos, permitindo TTLs longos.

#### 3.5.2 Erros de Origem
*   **Sintoma:** CloudFront retorna erros `5xx` (ex: `502 Bad Gateway`, `504 Gateway Timeout`) ou `4xx` (ex: `403 Forbidden`) que não são do WAF.
*   **Ações:**
    1.  **Verificar Origem:** Acessar a origem diretamente (ALB do ECS) para confirmar que está funcionando e retornando `200 OK`.
    2.  **Grupos de Segurança:** Verificar se o grupo de segurança do ALB permite tráfego do CloudFront (IPs ou prefixos gerenciados da AWS).
    3.  **Timeouts:** Aumentar `Origin Response Timeout` no CloudFront se a origem for lenta.
    4.  **Logs da Origem:** Inspecionar logs da aplicação no ECS para erros.
    5.  **Headers:** Verificar se os `Host` headers e outros headers necessários estão sendo encaminhados para a origem.

#### 3.5.3 Falsos Positivos do WAF
*   **Sintoma:** Requisições legítimas são bloqueadas pelo AWS WAF, resultando em erros `403 Forbidden` para usuários.
*   **Ações:**
    1.  **Logs do WAF:** Analisar logs do AWS WAF para identificar quais regras estão bloqueando as requisições.
    2.  **Amostras:** Usar a funcionalidade de "Sampled requests" do WAF para ver detalhes das requisições bloqueadas.
    3.  **Ajustar Regras:**
        *   Se uma regra gerenciada (Managed Rule) estiver causando o problema, você pode:
            *   Mudar a ação da regra para `COUNT` (contar sem bloquear) para testar.
            *   Adicionar exclusões de escopo (Scope Down Statements) para a regra.
        *   Se for uma regra personalizada, ajustar a lógica da regra.
    4.  **Adicionar IPs:** Adicionar IPs conhecidos (ex: IPs da equipe, IPs de parceiros) a uma lista de IP permitidos (IP Set) no WAF.

#### 3.5.4 Problemas de Certificado SSL/TLS
*   **Sintoma:** Erros de SSL/TLS ao acessar o CloudFront (ex: certificado expirado, nome de domínio incompatível).
*   **Ações:**
    1.  **ACM:** Verificar o status do certificado no AWS Certificate Manager (ACM).
    2.  **Expiração:** Confirmar que o certificado não está expirado e que a renovação automática está funcionando.
    3.  **Nome de Domínio:** Verificar se o nome de domínio personalizado no CloudFront corresponde ao Common Name (CN) ou Subject Alternative Name (SAN) do certificado.
    4.  **Associação:** Confirmar que o certificado está associado corretamente à distribuição CloudFront.

## 4. Guia de Resposta a Alarmes

Todos os alarmes são configurados no CloudWatch e notificam via SNS para o tópico `PlooralAlertsTopic`, que por sua vez envia mensagens para o canal Slack `#prod-alerts`.

### 4.1 Alarmes Críticos (P0/P1)

#### 4.1.1 `PlooralAPIHighErrorRate`
*   **Indica:** Taxa de erros HTTP 5xx (Server Error) para o serviço da API ECS está acima do threshold (ex: 5% em 5 minutos).
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar o painel de métricas do ALB e do serviço ECS para `HTTPCode_Target_5XX_Count` e `CPUUtilization`, `MemoryUtilization`.
    3.  Analisar logs do `/ecs/plooral-api` no CloudWatch Logs para erros específicos (`ERROR`, `FATAL`).
    4.  Iniciar investigação P0/P1 (Seção 1.1/1.2).
*   **Escalonamento:** Se a taxa de erros persistir ou aumentar, seguir matriz de escalonamento P0/P1.
*   **Falsos Positivos Comuns:** Deploy recente com bugs, problemas de dependência externa que se manifestam como 5xx.
*   **Verificação:** Taxa de erros retorna ao normal, sem 5xx visíveis nos logs.

#### 4.1.2 `PlooralWorkerFailure`
*   **Indica:** Função Lambda Worker (`plooral-worker`) está com alta taxa de erros (ex: >0 em 1 minuto).
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar métricas da Lambda (`Errors`, `DeadLetterErrors`) e logs (`/aws/lambda/plooral-worker`) no CloudWatch.
    3.  Verificar o SQS DLQ (`plooral-worker-dlq`) para acúmulo de mensagens.
    4.  Iniciar investigação P1 (Seção 1.2).
*   **Escalonamento:** Se erros persistirem e DLQ acumular, seguir matriz de escalonamento P1.
*   **Falsos Positivos Comuns:** Erros transientes que são automaticamente re-tentados.
*   **Verificação:** Métrica `Errors` da Lambda volta a zero, DLQ vazia ou em nível normal.

#### 4.1.3 `AuroraCPUCritical`
*   **Indica:** Uso de CPU da instância de escritor do Aurora acima do threshold (ex: >90% em 5 minutos).
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar métrica `CPUUtilization` e `DatabaseConnections` do Aurora no CloudWatch.
    3.  Usar Performance Insights para identificar queries ou sessões que estão consumindo mais CPU.
    4.  Verificar logs do Aurora para eventos incomuns.
    5.  Iniciar investigação P1 (Seção 1.2).
*   **Escalonamento:** Se o problema persistir e afetar o serviço, seguir matriz de escalonamento P1.
*   **Falsos Positivos Comuns:** Picos de tráfego esperados (se o auto-scaling não for configurado para DB).
*   **Verificação:** Uso de CPU retorna a níveis normais.

#### 4.1.4 `SQSQueueBacklog`
*   **Indica:** O número de mensagens visíveis na fila SQS principal (`plooral-queue`) excede um limite (ex: >1000 mensagens em 5 minutos).
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar métricas do SQS (`ApproximateNumberOfMessagesVisible`) e do Lambda Worker (`Invocations`, `Errors`).
    3.  Analisar logs da função Lambda Worker para erros que impedem o processamento.
    4.  Iniciar investigação P1 (Seção 1.2).
*   **Escalonamento:** Se o backlog crescer rapidamente e afetar o serviço, seguir matriz de escalonamento P1.
*   **Falsos Positivos Comuns:** Ingestão massiva de dados esperada que é processada em seguida.
*   **Verificação:** Backlog de mensagens na fila SQS diminui e normaliza.

### 4.2 Alarmes de Atenção (P2)

#### 4.2.1 `AuroraFreeStorageLow`
*   **Indica:** Espaço de armazenamento livre do Aurora abaixo de um threshold (ex: <10GB).
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar métrica `FreeStorageSpace` no CloudWatch.
    3.  Investigar o crescimento do banco de dados (ex: `pg_database_size`).
    4.  Verificar políticas de retenção de dados ou logs.
    5.  Criar um item de ação para analisar e limpar/arquivar dados, ou otimizar o schema.
*   **Escalonamento:** Se o espaço continuar diminuindo rapidamente, escalar para Platform Lead.
*   **Falsos Positivos Comuns:** Nenhum, este alarme geralmente indica um problema real a longo prazo.
*   **Verificação:** Espaço livre se estabiliza ou aumenta após ações.

#### 4.2.2 `CloudFront5XXErrors`
*   **Indica:** Taxa de erros HTTP 5xx originados do CloudFront (não necessariamente da origem) está acima do threshold.
*   **Primeiras Ações:**
    1.  Confirmar o alerta no Slack `#prod-alerts`.
    2.  Verificar métricas do CloudFront para `5xxErrorRate`.
    3.  Analisar logs de acesso do CloudFront (se habilitados) para padrões de erros.
    4.  Verificar a saúde da origem (ALB do ECS) diretamente.
    5.  Pode indicar problemas de configuração do CloudFront ou problemas de conexão com a origem.
*   **Escalonamento:** Se a taxa de erros persistir ou for alta, escalar para Platform Lead.
*   **Falsos Positivos Comuns:** Erros transientes da origem que o CloudFront repassa.
*   **Verificação:** Taxa de erros retorna ao normal.

## 5. Gerenciamento de Acesso

### 5.1 Concedendo Acesso ao Console AWS
1.  **Solicitação:** Novo membro da equipe ou parceiro solicita acesso via ticket (Jira/Confluence).
2.  **Criação de Usuário IAM (se externo/API):**
    *   Criar usuário IAM com credenciais de acesso programático (se for para API/CLI) ou apenas console.
    *   Gerar senha forte e forçar reset no primeiro login.
3.  **Anexar Política IAM (ou Adicionar a Grupo):**
    *   Anexar a política IAM de menor privilégio necessária para a função do usuário.
    *   Preferencialmente, adicionar o usuário a um grupo IAM existente com políticas apropriadas.
    *   Ex: `PlooralReadOnlyAccess`, `PlooralDeveloperAccess`, `PlooralAdminAccess`.
4.  **Configurar MFA:** Exigir MFA para todos os usuários do console.
5.  **Comunicar Credenciais:** Enviar credenciais de forma segura (ex: senha inicial via gerenciador de senhas, link do console, token MFA).

### 5.2 Revogando Acesso (Offboarding)
1.  **Notificação:** Receber notificação de offboarding (RH/Gerente).
2.  **Desabilitar Acesso Programático:** Remover chaves de acesso (Access Keys) do usuário IAM.
3.  **Desabilitar Acesso ao Console:** Desabilitar ou deletar o usuário IAM. Remover de todos os grupos IAM.
4.  **Remover Acesso em Outros Sistemas:** Remover acesso a VPN, Slack, Confluence, GitHub, etc.
5.  **Auditoria:** Verificar logs de acesso para o usuário desabilitado para garantir que não houve atividade após o offboarding.

### 5.3 Procedimentos de Acesso de Emergência
*   **Cenário:** Engenheiro on-call precisa de acesso elevado inesperado durante um incidente crítico e não consegue usar suas credenciais normais ou roles predefinidas.
*   **Procedimento:**
    1.  **Solicitação:** On-call solicita acesso elevado no canal `#prod-alerts`, explicando a necessidade e o escopo (`platform-lead` e `eng-manager` devem ser notificados).
    2.  **Ativação de Role de Emergência:**
        *   Assumir uma role IAM de emergência (ex: `arn:aws:iam::<ACCOUNT_ID>:role/PlooralEmergencyAdmin`) com privilégios temporários (via STS `AssumeRole`).
        *   Esta role deve ter políticas de condição que restringem o acesso apenas a IPs da VPN ou exigir MFA forte.
    3.  **Duração Limitada:** O acesso via role de emergência deve ser concedido com duração mínima necessária (ex: 1 hora) e revogado automaticamente.
    4.  **Auditoria:** Todos os acessos de emergência são logados no CloudTrail e devem ser revisados em post-mortems ou auditorias de segurança.

### 5.4 Procedimentos de Rotação de Chaves
*   **Chaves de Acesso IAM (para usuários programáticos):**
    1.  **Notificação:** Notificar o proprietário da chave para criar uma nova chave.
    2.  **Criação de Nova Chave:** O proprietário cria uma nova chave de acesso.
    3.  **Atualização da Aplicação:** Atualizar todas as aplicações/serviços que usam a chave antiga para usar a nova.
    4.  **Desativação da Chave Antiga:** Após validação, desativar a chave antiga.
    5.  **Deleção da Chave Antiga:** Após um período de carência (ex: 7 dias), deletar a chave antiga.
*   **Secrets no SSM Parameter Store:**
    1.  **Atualizar Parâmetro:** No console do SSM Parameter Store, editar o parâmetro `SecureString` e inserir o novo valor.
    2.  **Reiniciar Serviços:** Reiniciar as tarefas do ECS ou redeploy das Lambdas que dependem desse secret para que elas carreguem o novo valor.
    *   `aws ecs update-service --cluster plooral-cluster --service plooral-api-service --force-new-deployment`
*   **Certificados SSL/TLS (ACM):**
    1.  A maioria dos certificados gerenciados pelo ACM são renovados automaticamente.
    2.  Monitorar eventos do ACM para falhas na renovação.
    3.  Se um certificado manual for usado, iniciar o processo de renovação antes da expiração.
