// ============================================================================
//  Projeto : Braco Robotico de Coleta de Amostras (Docking & Retrieval)
//  Peca    : GARRA (Grip) - mecanismo de engrenagens gemeas acionado por 1 servo
//  Evento  : Global Solution 2026 - Industria Espacial
//  Curso   : FIAP - Engenharia de Software - 4o Ano (Presencial)
//  Materia : Project-Based Maker Lab (PBML)
//
//  Author  : RODRIGO BRASILEIRO - RM98952
//
//  Conceito: garra de captura de amostras/detritos em microgravidade. Um unico
//  servo SG90 (9g) aciona o "dedo motor"; um segundo dedo (seguidor) engrena no
//  primeiro e fecha de forma simetrica. As pontas tem um bercco concavo que
//  abraca uma amostra esferica (ex.: regolito / detrito orbital). Compativel com
//  o firmware: comando O abre a garra (GRIP_OPEN) e C fecha (GRIP_CLOSE).
//
//  TUDO E PARAMETRICO: altere a secao "PARAMETROS" para reescalar a peca.
//  Exportacao: render (F6) e depois "Export as STL" -> garra.stl
// ============================================================================

/* [ Selecao de peca p/ render/export ] */
// "assembly" para ver montado; demais para exportar/imprimir cada peca.
part = "assembly";  // [assembly, base, driver_finger, follower_finger, sample, print_plate]

/* [ Qualidade ] */
$fn = 64;

// ---------------------------------------------------------------------------
//                                PARAMETROS
// ---------------------------------------------------------------------------

/* [ Servo SG90 (9g) - encaixe ] */
servo_l       = 22.8;   // comprimento do corpo
servo_w       = 12.2;   // largura do corpo
servo_h       = 22.5;   // altura do corpo
servo_clear   = 0.5;    // folga de encaixe (impressao)
shaft_offset  = 5.9;    // eixo a partir de uma extremidade do corpo
shaft_d       = 5.0;    // diametro do eixo estriado (acopla ao horn)
flange_l      = 32.2;   // comprimento total com as abas de fixacao
flange_t      = 2.6;    // espessura da aba
flange_drop   = 2.5;    // distancia do topo do corpo ate a aba
screw_span    = 28.0;   // distancia entre os furos das abas
screw_d       = 2.3;    // furo das abas (parafuso M2)
horn_screw_d  = 2.2;    // parafuso central do horn

/* [ Engrenagens dos dedos ] */
gear_teeth    = 12;     // numero de dentes
gear_mod      = 2.0;    // modulo da engrenagem
gear_th       = 6.0;    // espessura (altura) da engrenagem/dedo
pivot_d       = 3.2;    // pino do dedo seguidor

/* [ Dedos / garra ] */
finger_len    = 40.0;   // comprimento do dedo (do eixo ate a ponta)
finger_w      = 9.0;    // largura do dedo
grip_n        = 5;      // n. de serrilhas de aderencia
tip_reach     = 0.85;   // fracao do comprimento usada p/ as pontas se encontrarem
open_angle    = 12;     // abertura no preview (graus a partir da garra FECHADA)
sample_d      = 16.0;   // diametro da amostra esferica (referencia)

/* [ Base / suporte ] */
base_th       = 4.0;    // espessura da base
standoff      = 2.5;    // folga vertical entre base e engrenagens
base_margin   = 9.0;    // margem ao redor dos eixos

/* [ Interface com o braco (link/articulacao) ] */
arm_bore      = 5.2;    // furo central de acoplamento ao braco
arm_screw_d   = 2.6;    // furos do padrao de fixacao
arm_pattern   = 16.0;   // distancia entre furos de fixacao no braco

/* [ Etiqueta ] */
show_label    = true;
label_txt     = "PBML";

// ---------------------------------------------------------------------------
//                          GRANDEZAS DERIVADAS
// ---------------------------------------------------------------------------
pitch_r  = gear_mod * gear_teeth / 2;     // raio primitivo
out_r    = pitch_r + gear_mod;            // raio externo
root_r   = pitch_r - 1.25 * gear_mod;     // raio de base
center_d = gear_mod * gear_teeth;         // distancia entre eixos (engr. iguais)

sx = -center_d / 2;   // eixo do dedo MOTOR (alinhado ao eixo do servo)
fx =  center_d / 2;   // eixo do dedo SEGUIDOR (pino)
body_cy = shaft_offset - servo_l / 2;     // centro Y do corpo do servo (eixo em y=0)

// inclinacao interna p/ as pontas se encontrarem no centro (garra fechada)
A_close = atan2(center_d / 2, finger_len * tip_reach);

// limites da base
bx0 = sx - base_margin;
bx1 = fx + base_margin;
by0 = body_cy - servo_l/2 - 12;           // cauda traseira p/ fixacao no braco
by1 = out_r + 4;                          // frente (lado dos dedos)

// ---------------------------------------------------------------------------
//                          UTILITARIOS DE GEOMETRIA
// ---------------------------------------------------------------------------
function P(r, a) = [ r * cos(a), r * sin(a) ];

// Retangulo de cantos arredondados (canto inferior-esq em x0,y0)
module rrect(x0, y0, x1, y1, h, r) {
    hull() {
        translate([x0 + r, y0 + r, 0]) cylinder(r = r, h = h);
        translate([x1 - r, y0 + r, 0]) cylinder(r = r, h = h);
        translate([x1 - r, y1 - r, 0]) cylinder(r = r, h = h);
        translate([x0 + r, y1 - r, 0]) cylinder(r = r, h = h);
    }
}

// Perfil 2D de engrenagem (dentes trapezoidais que engrenam)
module gear_2d(teeth, m) {
    rp = m * teeth / 2;
    ro = rp + m;
    rr = rp - 1.25 * m;
    a  = 360 / teeth;
    union() {
        circle(r = rr + 0.02);
        for (i = [0 : teeth - 1])
            rotate(i * a)
                polygon([
                    P(rr, -a * 0.25), P(rp, -a * 0.20), P(ro, -a * 0.12),
                    P(ro,  a * 0.12), P(rp,  a * 0.20), P(rr,  a * 0.25)
                ]);
    }
}

// ---------------------------------------------------------------------------
//                          PERFIL DO DEDO (2D)
//  Aponta para +Y; lado interno (que segura a amostra) = +X.
// ---------------------------------------------------------------------------
module finger_2d() {
    difference() {
        union() {
            gear_2d(gear_teeth, gear_mod);             // engrenagem do dedo
            // braco do dedo
            hull() {
                translate([0, 2])               circle(d = finger_w + 3);
                translate([1.5, finger_len])    circle(d = finger_w * 0.75);
            }
            // gancho/ponta curvando para dentro (+X)
            hull() {
                translate([1.5, finger_len])                          circle(d = finger_w * 0.75);
                translate([finger_w * 0.7, finger_len + finger_w*0.15]) circle(d = finger_w * 0.5);
            }
        }
        // bercco concavo da amostra na PONTA (abre para frente, +Y).
        // os dois dedos juntos formam o bercco que abraca a esfera.
        translate([finger_w * 0.15, finger_len + sample_d * 0.22]) circle(r = sample_d / 2);
        // serrilhas de aderencia na face interna proxima da ponta
        for (i = [0 : grip_n - 1])
            translate([finger_w / 2 - 0.2, finger_len * 0.55 + i * (finger_len * 0.06)])
                circle(r = 0.8, $fn = 3);
        // furo de aligeiramento no corpo do braco
        translate([0.5, finger_len * 0.5]) circle(d = finger_w * 0.42);
    }
}

// ---------------------------------------------------------------------------
//                          DEDOS (3D)
// ---------------------------------------------------------------------------
// Dedo MOTOR: acopla ao eixo/horn do servo (cubo central removido = encaixe).
module driver_finger() {
    difference() {
        union() {
            linear_extrude(gear_th) finger_2d();
            // cubo de reforco do acoplamento sob a engrenagem
            translate([0, 0, -standoff]) cylinder(d = shaft_d + 5, h = standoff + 0.1);
        }
        // furo passante do eixo estriado
        translate([0, 0, -standoff - 1]) cylinder(d = shaft_d, h = gear_th + standoff + 2);
        // rebaixo p/ parafuso central do horn
        translate([0, 0, gear_th - 2.4]) cylinder(d = horn_screw_d + 3, h = 3);
    }
}

// Dedo SEGUIDOR: gira livre sobre o pino da base.
module follower_finger() {
    difference() {
        linear_extrude(gear_th) finger_2d();
        translate([0, 0, -1]) cylinder(d = pivot_d + 0.4, h = gear_th + 2);  // mancal
    }
}

// ---------------------------------------------------------------------------
//                          AMOSTRA (referencia)
// ---------------------------------------------------------------------------
module sample() {
    sphere(d = sample_d);
}

// ---------------------------------------------------------------------------
//                          NEGATIVOS DA BASE
// ---------------------------------------------------------------------------
module servo_negative() {
    // bolsa do corpo do servo (vaza toda a base)
    translate([sx, body_cy, -base_th/2])
        cube([servo_w + servo_clear, servo_l + servo_clear, base_th + 2], center = true);
    // alivio do eixo / horn
    translate([sx, 0, -1]) cylinder(d = shaft_d + 9, h = base_th + 2);
    // furos das abas de fixacao do servo
    for (s = [-1, 1])
        translate([sx, body_cy + s * screw_span/2, -1]) cylinder(d = screw_d, h = base_th + 2);
}

// Padrao de fixacao ao braco (furo central + cruz de parafusos), no fundo traseiro.
module arm_mount_negative() {
    my = by0 + 7;                                                      // centro da cauda traseira
    translate([0, my, -1]) cylinder(d = arm_bore, h = base_th + 2);   // furo central
    for (s = [-1, 1])                                                 // 2 furos laterais (padrao do braco)
        translate([s * arm_pattern/2, my, -1]) cylinder(d = arm_screw_d, h = base_th + 2);
}

// ---------------------------------------------------------------------------
//                          BASE / SUPORTE
// ---------------------------------------------------------------------------
module base() {
    difference() {
        union() {
            // placa principal (topo em z=0)
            translate([0, 0, -base_th])
                rrect(bx0, by0, bx1, by1, base_th, 4);
            // boss + pino solido do dedo seguidor (mancal do giro)
            translate([fx, 0, 0]) cylinder(d = pivot_d + 7, h = standoff);
            translate([fx, 0, 0]) cylinder(d = pivot_d, h = standoff + gear_th + 1.5);
        }
        servo_negative();      // bolsa do servo + alivio do eixo/horn + furos das abas
        arm_mount_negative();  // fixacao ao braco (cauda traseira, livre do servo)
        // (o dedo motor e sustentado pelo horn do servo; nao precisa de boss)
        // etiqueta gravada no topo
        if (show_label)
            translate([0, by1 - 6, -0.6])
                linear_extrude(1.2)
                    text(label_txt, size = 5, halign = "center", valign = "center",
                         font = "Arial:style=Bold");
    }
}

// ---------------------------------------------------------------------------
//                          SERVO (modelo de referencia p/ preview)
// ---------------------------------------------------------------------------
module sg90_ref() {
    color([0.25, 0.45, 0.75]) {
        translate([0, body_cy, -servo_h/2]) cube([servo_w, servo_l, servo_h], center = true);
        translate([0, body_cy, -flange_drop - flange_t/2]) cube([servo_w, flange_l, flange_t], center = true);
        cylinder(d = shaft_d, h = 4);
        translate([0, 0, 3]) cube([3, 22, 3], center = true);  // horn
    }
}

// ---------------------------------------------------------------------------
//                          MONTAGEM (preview)
// ---------------------------------------------------------------------------
module assembly() {
    color([0.85, 0.85, 0.88]) base();
    translate([sx, 0, 0]) sg90_ref();

    ang = -A_close + open_angle;   // angulo do dedo motor (inclina p/ dentro)

    // dedo motor (esquerdo) - acionado pelo servo
    color([0.95, 0.62, 0.10])
        translate([sx, 0, standoff])
            rotate([0, 0, ang]) driver_finger();

    // dedo seguidor (direito) = espelho do motor -> fecha simetrico e engrena
    color([0.95, 0.62, 0.10])
        translate([fx, 0, standoff])
            rotate([0, 0, -ang]) mirror([1, 0, 0]) follower_finger();

    // amostra capturada entre as pontas
    color([0.55, 0.78, 0.95])
        translate([0, finger_len * 0.9, standoff + gear_th/2]) sample();
}

// ---------------------------------------------------------------------------
//                          LAYOUT DE IMPRESSAO
// ---------------------------------------------------------------------------
module print_plate() {
    base();
    translate([0, by1 + 18, standoff]) driver_finger();
    translate([22, by1 + 18, 0])       follower_finger();
}

// ---------------------------------------------------------------------------
//                          DISPATCH
//  (suprimido quando importado por outro .scad via GARRA_AS_LIBRARY = true)
// ---------------------------------------------------------------------------
if (is_undef(GARRA_AS_LIBRARY)) {
    if      (part == "assembly")        assembly();
    else if (part == "base")            base();
    else if (part == "driver_finger")   driver_finger();
    else if (part == "follower_finger") follower_finger();
    else if (part == "sample")          sample();
    else if (part == "print_plate")     print_plate();
    else                                assembly();
}
