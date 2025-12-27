# Scenario 1 — Questions

Answer these questions in `answer-template/ANSWERS.md` under the Scenario 1 section.

---

## Question 1.1 — First 10 Minutes

You've just been paged. You have 10 minutes before the next escalation tier is notified.

**What are your first 10-minute actions?**  

💡 **Resposta:** Meu foco imediato é entender o raio da explosão, reunir informações críticas e me comunicar de forma eficaz. Evitarei tomar quaisquer ações disruptivas imediatas até que eu tenha uma hipótese clara.

Consider:
- What do you check first and why?  
  💡 **Resposta:**  
      Confirmar o recebimento do alerta em `#prod-alerts` com: "Alerta recebido. Investigando."  
      Informar à equipe que estou ciente, evitando esforços duplicados.  
      Revisar o painel de alarmes e eventos recentes.  Vou examinar o `CONTEXT.md` e `cloudwatch_alarms.json`.  Obter uma visão geral de alto nível do que está disparando e a sequência de eventos. Os principais alarmes são latência, erros 5xx, hosts não saudáveis e profundidade da fila SQS. A linha do tempo aponta para a implantação v2.5.0 como um gatilho potencial.    
  
- What information do you need to gather?  
  💡 **Resposta:**  
  Verificar a saúde do serviço ECS e do banco de dados Aurora.  
     Olhar os eventos do serviço ECS (`ecs_service.log`) e as métricas do RDS (`cloudwatch_metrics.json`, `rds_slowquery.log`).<br>
  O alarme `unhealthy-hosts` é crítico. Preciso saber por que as tarefas estão falhando. CPU/conexões altas no BD são um forte indicador de um problema no banco de dados.<br> Formular uma hipótese rápida: Com base na implantação da v2.5.0 e nos logs de consulta lenta, minha hipótese inicial é que a nova consulta de recomendação está causando contenção no banco de dados e alta latência.<br> Isso me dá uma linha específica para investigar.
                
- Who do you communicate with?  
  💡 **Resposta:**  
            Postar uma breve atualização em `#prod-alerts`: "Descoberta inicial: Alta latência e erros se correlacionam com a implantação v2.5.0. Suspeita-se que uma nova consulta ao banco de dados seja a causa. Estou investigando a consulta e proporei um plano de mitigação nos próximos 10 minutos. No momento, não estou tomando nenhuma ação."  Manter as partes interessadas informadas e gerenciar as expectativas. É importante declarar o que eu *não* estou fazendo para evitar pânico ou ações prematuras.    
- What do you NOT do yet?<br>
  💡 **Resposta**:
*   **Reverter imediatamente a implantação.** Embora seja um culpado provável, uma reversão é disruptiva. Preciso ter certeza de que é a decisão certa.
*   **Reiniciar serviços.** Isso pode destruir dados forenses valiosos e pode não resolver o problema subjacente.
*   **Desativar o WAF.** O WAF é provavelmente um sintoma (bloqueando tentativas legítimas), não a causa. Desativá-lo poderia nos expor a ameaças reais.

---

## Question 1.2 — Alarm Correlation

Multiple alarms fired in quick succession. Review the `cloudwatch_alarms.json` file.

**How do you correlate these alarms? What story do they tell?**
💡 **Resposta:**  
Os alarmes contam uma história clara de uma falha em cascata originada na camada da aplicação e impactando todo o ciclo de vida da solicitação.

Consider:
- Which alarm is the leading indicator?<br>
  _Indicador Principal:_ _plooral-api-p99-latency(14:17 UTC). Este foi o primeiro sinal de problema, indicando que a própria aplicação estava ficando lenta._
- Which alarms are symptoms vs. causes?
- Are any alarms misleading or red herrings?  
  💡 **Resposta:** <br>
  **_A História:_**
    1.  **Alta Latência (`plooral-api-p99-latency`):** A aplicação começa a levar mais tempo para processar as solicitações. Esta é a raiz do problema.
    2.  **Erros 5xx (`plooral-api-5xx-rate`):** À medida que as solicitações expiram, o ALB e outros serviços upstream começam a retornar erros 5xx. O `alb_access.log` mostra erros `504` (Gateway Timeout) e `502` (Bad Gateway).
    3.  **Hosts Não Saudáveis (`plooral-api-unhealthy-hosts`):** As verificações de saúde do ECS, que provavelmente estão atingindo um endpoint de verificação de saúde agora lento, começam a falhar. Isso faz com que o serviço ECS recicle as tarefas, piorando o problema, pois as novas tarefas também podem falhar. O `ecs_service.log` confirma isso, mostrando tarefas falhando com códigos `504` e erros `OOMKilled`.
    4.  **Profundidade da Fila SQS (`plooral-tasks-queue-depth`):** A Lambda `plooral-worker`, que processa mensagens da fila SQS, também é provavelmente impactada pelo banco de dados lento. Ela não consegue processar mensagens rápido o suficiente, fazendo com que a fila aumente. O `lambda.log` e `sqs_metrics.json` confirmam isso, mostrando timeouts do banco de dados e uma fila crescente.
    5.  **Pico de Bloqueios no WAF (`plooral-waf-block-spike`):** Este é um **sintoma**, não uma causa. À medida que os usuários encontram erros, eles tentam novamente suas solicitações, levando a um pico de tráfego de usuários legítimos. Isso aciona a regra de limitação de taxa do WAF. O `waf_sample_requests.log` mostra agentes de usuário de aparência legítima sendo bloqueados. Esta é uma pista falsa em termos de causa raiz, mas um indicador claro do impacto no usuário.
    6.  **Conexões Aurora (`plooral-aurora-connections`):** Este é um sintoma direto da consulta lenta. As consultas de longa duração estão mantendo as conexões abertas, levando ao esgotamento do pool de conexões.

---

## Question 1.3 — Hypothesis Ranking

Based on your analysis of the artifacts, list your hypotheses for the root cause.

**Rank your hypotheses from most to least likely. Explain your reasoning.**

Format your answer as:

| Rank | Hypothesis | Supporting Evidence | Against Evidence |
|------|------------|---------------------|------------------|
| 1 | A nova implantação v2.5.0 introduziu uma consulta de banco de dados ineficiente que está causando alta latência e contenção de recursos. | - **Cronologia:** O incidente começou minutos após a conclusão da implantação v2.5.0. <br>- **Logs:** `rds_slowquery.log` mostra uma nova consulta muito cara (`-- NEW QUERY IN v2.5.0 - User Recommendations`) com `Query_time` e `Lock_time` altos a partir das 14:15 UTC. <br>- **Métricas:** `cloudwatch_metrics.json` mostra a CPU e as conexões do Aurora aumentando após as 14:10 UTC. <br>- **Mudança no Código:** `CONTEXT.md` afirma explicitamente que a mudança da v2.5.0 foi uma "Nova consulta de banco de dados para recomendações de usuários" que "não foi revisada por um DBA". | Nenhuma. A evidência é esmagadora. |
| 2 | Um ator malicioso está lançando um ataque DDoS, causando a alta carga e acionando o WAF. | - **Alarme do WAF:** O alarme `plooral-waf-block-spike` está disparando. <br>- **Aumento de Tráfego:** `cloudwatch_metrics.json` mostra um leve aumento no `RequestCount`. | - **Logs do WAF:** `waf_sample_requests.log` mostra agentes de usuário legítimos e uma nota de que provavelmente são novas tentativas. <br>- **Concentração Geográfica:** O pico de tráfego é de `ap-southeast-1`, que pode ser uma base de usuários legítima. Um DDoS sofisticado provavelmente seria mais distribuído. <br>- **A consulta lenta:** Um ataque DDoS não explicaria o aparecimento súbito de uma nova consulta lenta nos logs. |
| 3 | Uma dependência downstream (por exemplo, uma API externa) está lenta ou indisponível, fazendo com que as solicitações fiquem presas. | - **Erros 5xx:** A aplicação está retornando erros 5xx, que podem ser causados por falhas downstream. | - **Nenhuma Evidência:** Não há menção de nenhuma dependência externa no diagrama de arquitetura ou nos logs. <br>- **Métricas do Banco de Dados:** As métricas do Aurora apontam diretamente para o banco de dados como o gargalo, não um serviço externo. |

---

## Question 1.4 — Immediate Mitigation

It's now 14:25 UTC. You need to stop the bleeding.

**What immediate mitigation steps do you take? In what order?**

For each step:
- What action do you take?
- What is the expected outcome?
- What could go wrong?
- How do you verify success?<br>
💡 **Resposta:** <br>

| Passo | Ação | Resultado Esperado | O que Pode Dar Errado? | Como Verificar o Sucesso |
|---|---|---|---|---|
| 1 | **Iniciar a Reversão (Rollback) do Serviço ECS `plooral-api` para v2.4.1** | A consulta ineficiente será removida da aplicação. Isso deve reduzir imediatamente a carga no banco de dados. | A reversão pode falhar, ou a imagem v2.4.1 pode ter seus próprios problemas (improvável, pois era a versão estável anterior). A infraestrutura (CodeDeploy) pode ter problemas. | - Monitorar os eventos do serviço ECS para garantir que a reversão seja concluída com sucesso e que todas as tarefas estejam executando a v2.4.1. <br>- Observar a métrica `TargetResponseTime_p99` no CloudWatch; ela deve começar a diminuir significativamente em minutos. |
| 2 | **Monitorar Métricas Chave** | Conforme a reversão avança, espero ver uma recuperação rápida. | O sistema pode não se recuperar, indicando um problema diferente ou adicional. | - **`plooral-api-p99-latency`:** Deve cair abaixo do limiar de 2000ms. <br>- **`plooral-api-5xx-rate`:** Deve cair para perto de zero. <br>- **`plooral-api-unhealthy-hosts`:** Deve ir para 0 à medida que as tarefas se tornam saudáveis. <br>- **`plooral-aurora-cpu` & `plooral-aurora-connections`:** Devem diminuir para os níveis normais. <br>- **`plooral-tasks-queue-depth`:** Deve começar a diminuir à medida que a Lambda do worker consegue processar as mensagens novamente. |
| 3 | **Comunicar o Status** | Manter as partes interessadas informadas sobre a mitigação e recuperação em andamento. | A má comunicação pode causar confusão. | - Postar uma atualização em `#prod-alerts`: "Mitigação em andamento. Revertendo `plooral-api` para v2.4.1 para resolver a suspeita de consulta ruim. Monitorando a recuperação. Próxima atualização em 5 minutos." <br>- Assim que as métricas se recuperarem, postar: "A reversão foi concluída e as métricas estão voltando ao normal. O incidente imediato está resolvido. Estamos agora em fase de monitoramento." |

---

## Question 1.5 — Permanent Fix

After the incident is mitigated, you need to ensure it doesn't happen again.

**What is the root cause? What permanent fix do you propose?**

Consider:
- What code/config changes are needed?
- What process changes are needed?
- What guardrails should be added?<br>
💡 **Resposta:** <br>
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

---

## Question 1.6 — Postmortem

The incident is resolved. You need to write a postmortem.

**Provide an outline of the postmortem document.**

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

## Bonus Questions

### Bonus 1.A — WAF False Positives

The WAF blocked legitimate traffic from `ap-southeast-1`. 

**How do you handle this without disabling the WAF entirely?**  

:bulb:**Resposta:** Ajustar o limite da taxa, o limite atual é de 2000 solicitações por 300 segundos, é pouco para um novo storm, vamos aumentar esse limite, mas apenas para agentes de usuário ou intervalos de IP específicos e confiáveis ​​se possível.
          Direcionar a regra, está bloqueando solicitações para /vi/recommendations, podemos criar uma mais específica que se aplicasse um limite de taxa mais alto apenas para este ponto final ou aumentar temporariamente o limite para todos os endpoints até que o problema subjacente seja resolvido.
          Usar uma métrica diferente, em vez de apenas contar solicitações, a regra do WAF pode ser baseada em uma combinação de fatores, como contagem de solicitações de um único IP "e" uma alta taxa de erros 5x desde a origem, isso permitiria ao WAF diferenciar entre um ataque malicioso e uma invasão.
          Criar uma lista de IPs permitidos, se tivermos um conjunto conhecido de intervalos de IPs confiáveis (por exemplo, para parceiros corporativos), podemos adicioná-los a uma lista de permissões para ignorar a regra de limitação de taxa.

### Bonus 1.B — SQS Queue Backlog

After the incident, there are 15,000+ messages in the SQS queue.

**How do you safely process this backlog? What's your strategy?**  

💡 **Resposta:** Confirmar que a causa raiz (a consulta incorreta) seja resolvida. O Lambda `plooral-worker` continuará falhando se o banco de dados ainda está sob pressão. Temporariamente dar um scale down, deixar o lambda como 0 para evitar que ele extraia mais mensagens da fila. Isso vai dar um backlog estável para trabalhar. Inspecionar uma amostra de mensagens da fila (e o DLQ) para entender o que são. São todos iguais? Mesmo tipo? Podem ser reprocessados ​​com segurança? Se sim, provavelmente são uma mistura de user.recommendation.generated e outros eventos.

### Bonus 1.C — Aurora Connection Exhaustion

The connection pool nearly exhausted (285/300).

**What changes would you make to prevent this in the future?**  

💡 **Resposta:** A solução mais eficaz é implementar o Amazon RDS Proxy. Pooling de Conexões: O RDS Proxy ficaria entre a aplicação e o banco de dados, compartilhando e reutilizando conexões de banco de dados. Isso reduziria drasticamente o número de conexões necessárias no próprio banco de dados.  

   O RDS Proxy também pode melhorar a resiliência, continuando a aceitar conexões mesmo que o banco de dados esteja temporariamente indisponível, e pode ajudar a prevenir tempestades de conexões.  
   
   Aumentar o max_connections, esta é uma correção de curto prazo, não uma solução de longo prazo. Embora eu pudesse aumentar o parâmetro max_connections no cluster Aurora, é melhor resolver o problema de gerenciamento de conexões subjacente.  
   
   Pooling de Conexões do Lado da Aplicação, Garantir que a aplicação esteja usando uma biblioteca de pool de conexões moderna e eficiente. No entanto, em um ambiente sem servidor como o Fargate, onde as tarefas podem aumentar e diminuir rapidamente, uma solução centralizada como o RDS Proxy é superior.  
   
   Timeouts de Consulta, Como mencionado na correção permanente, implementar timeouts de consulta estritos na aplicação evitaria que uma única consulta de longa duração mantivesse uma conexão aberta indefinidamente.       

