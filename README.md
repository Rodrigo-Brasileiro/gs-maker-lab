# TPGN Maker GS - Braco Robotico de Coleta de Amostras

Projeto desenvolvido para a Global Solution 2026 da FIAP, com foco em Industria Espacial, usando Arduino, servomotores e modelagem 3D parametrica em OpenSCAD.

O sistema simula um braco robotico de 2 graus de liberdade para operacoes de docking & retrieval, isto e, captura, manipulacao e recolhimento de amostras ou pequenos detritos em um cenario inspirado em microgravidade.

## Visao geral

O prototipo e composto por:

| Area | Descricao |
| --- | --- |
| Controle | Firmware Arduino com comandos via Monitor Serial |
| Atuadores | 2 micro servos SG90: articulacao do braco e garra |
| Sinalizacao | LED de status para indicar garra fechada |
| Simulacao | Circuito publico no Tinkercad |
| Modelagem | Pecas mecanicas parametrizadas em OpenSCAD |
| Impressao 3D | Arquivos STL exportados para braco, base, elo e dedos da garra |

## Objetivo

Criar um demonstrador funcional de um mecanismo robotico simples, capaz de:

- Subir e descer a articulacao principal do braco.
- Abrir e fechar uma garra mecanica acionada por servo.
- Sinalizar visualmente quando a amostra esta capturada.
- Representar, em escala didatica, uma aplicacao de coleta de amostras, manutencao orbital ou captura de detritos espaciais.

## Integrantes

| Nome | RM |
| --- | --- |
| Guilherme Rocha Bianchini | RM97974 |
| Nikolas Rodrigues Moura dos Santos | RM551566 |
| Pedro Henrique Pedrosa Tavares | RM97877 |
| Rodrigo Brasileiro | RM98952 |
| Thiago Jardim de Oliveira | RM551624 |

Grupo: `TPGN - TechPulse Global Network`

## Links da entrega

| Recurso | Link |
| --- | --- |
| Simulador do circuito no Tinkercad | [Abrir projeto](https://www.tinkercad.com/things/aPYhfb0wO8s/editel?returnTo=%2Fusers%2F0ihK8cLdiOE&sharecode=gYKTYNBTAVL7AkND236sMprZ-sYblSV4BKXsZEcPdEs) |

## Estrutura do repositorio

```text
TPGN_MAKER_GS/
|-- README.md
|-- src/
|   `-- braco_robotico.ino
`-- model/
    |-- braco_robotico.scad
    |-- garra.scad
    |-- braco_robotico.stl
    |-- arm_base.stl
    |-- arm_link.stl
    |-- garra.stl
    |-- garra_base.stl
    |-- driver_finger.stl
    `-- follower_finger.stl
```

## Hardware e componentes

| Componente | Funcao |
| --- | --- |
| Arduino Uno R3 | Controlador do circuito |
| 2x micro servo SG90 9g | Movimento do braco e abertura/fechamento da garra |
| LED | Indicador de garra fechada |
| Resistor 220 ohm | Limitacao de corrente do LED |
| Fonte externa 5 V  | Alimentacao recomendada para os servos |
| Protoboard e jumpers | Conexoes eletricas |

Importante: para montagem fisica, os servos devem ser alimentados por fonte externa de 5 V ou 6 V, mantendo GND comum com o Arduino. Evite alimentar os servos diretamente pelo pino 5V do Arduino.

## Pinagem

| Pino Arduino | Conexao |
| --- | --- |
| `D9` | Sinal do Servo 1 - articulacao do braco |
| `D10` | Sinal do Servo 2 - garra |
| `D7` | LED de status com resistor de 220 ohm |
| `GND` | Terra comum entre Arduino, fonte e servos |

## Firmware

O firmware esta em [`src/braco_robotico.ino`](src/braco_robotico.ino) e usa a biblioteca padrao `Servo.h`.

Configuracoes principais:

| Parametro | Valor |
| --- | --- |
| Baud rate | `9600` |
| Angulo inicial do braco | `90` graus |
| Limite minimo do braco | `10` graus |
| Limite maximo do braco | `170` graus |
| Passo por comando | `15` graus |
| Garra aberta | `120` graus |
| Garra fechada | `30` graus |
| Delay de movimento | `15 ms` por grau |

## Comandos do Monitor Serial

Abra o Monitor Serial em `9600 baud`, envie um caractere e pressione Enter.

| Comando | Acao | Servo |
| --- | --- | --- |
| `U` | Sobe a articulacao do braco | Servo 1 |
| `D` | Desce a articulacao do braco | Servo 1 |
| `O` | Abre a garra | Servo 2 |
| `C` | Fecha a garra | Servo 2 |
| `H` | Volta as garras a posição inicial | Servo 1 e 2 |
Comportamento do LED:

- LED aceso: garra fechada, representando amostra capturada.
- LED apagado: garra aberta.
- Comandos invalidos são informados no Monitor Serial.

## Modelos 3D

Os modelos foram criados em OpenSCAD de forma parametrica, permitindo ajustar dimensoes, folgas, encaixes e layout de exportacao.

| Arquivo | Descricao |
| --- | --- |
| `model/garra.scad` | Modelo parametrico da garra com engrenagens gemeas |
| `model/braco_robotico.scad` | Montagem completa do braco 2-DOF, importando a garra |
| `model/garra.stl` | STL da garra montada |
| `model/garra_base.stl` | STL da base da garra |
| `model/driver_finger.stl` | STL do dedo motor da garra |
| `model/follower_finger.stl` | STL do dedo seguidor da garra |
| `model/braco_robotico.stl` | STL da montagem do braco |
| `model/arm_base.stl` | STL da base do braco |
| `model/arm_link.stl` | STL do elo do braco |

### Garra

A garra usa um mecanismo de engrenagens gemeas. Um servo aciona o dedo motor, enquanto o dedo seguidor acompanha o movimento por engrenamento, fechando de forma simetrica. As pontas possuem geometria concava para envolver uma amostra esferica de referencia.

### Braço

O arquivo `braco_robotico.scad` reutiliza os modulos de `garra.scad` e adiciona:

- Base do braço.
- Suporte do ombro.
- Elo principal.
- Acoplamento da garra ao punho.
- Suporte opcional para LED.

## Como reproduzir

1. Abra o projeto do Tinkercad pelo link da entrega.
2. Verifique se o circuito usa GND comum entre Arduino e fonte dos servos.
3. Inicie a simulacao.
4. Abra o Monitor Serial em `9600 baud`.
5. Envie os comandos `U`, `D`, `O`, `C` e `H` para testar os movimentos.
6. Para uso fisico, abra `src/braco_robotico.ino` na Arduino IDE e envie o codigo para um Arduino Uno.
7. Para visualizar ou alterar as pecas, abra os arquivos `.scad` no OpenSCAD.
8. Para exportar novos STLs, renderize com `F6` e use `File > Export > Export as STL`.

## Tecnologias utilizadas

- Arduino Uno
- Arduino IDE
- Biblioteca `Servo.h`
- Tinkercad Circuits
- OpenSCAD
- Modelos STL para impressao 3D

## Relacao com ODS

O projeto se conecta ao ODS 9 - Industria, Inovacao e Infraestrutura, pois explora automacao, prototipagem, sistemas embarcados e modelagem mecanica aplicados a um problema inspirado na industria espacial.
