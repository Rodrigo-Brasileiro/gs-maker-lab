// ============================================================================
//  Projeto : Braco Robotico de Coleta de Amostras (Docking & Retrieval)
//  Peca    : BRACO COMPLETO 2-DOF (ombro que sobe/desce + mao que abre/fecha)
//  Evento  : Global Solution 2026 - Industria Espacial
//  Curso   : FIAP - Engenharia de Software - 4o Ano (Presencial)
//  Materia : Project-Based Maker Lab (PBML)
//
//  Author  : RODRIGO BRASILEIRO - RM98952
//
//  Conceito: braco de 2 graus de liberdade fiel ao circuito de 2 servos.
//    - SERVO 1 (ombro): gira o elo p/ cima/baixo  -> comandos U / D (firmware)
//    - SERVO 2 (mao)  : abre/fecha a garra         -> comandos O / C (firmware)
//  A mao reaproveita o mecanismo de engrenagens gemeas validado em garra.scad.
//
//  Reuso modular: este arquivo IMPORTA garra.scad (modulos validados) sem
//  duplicar geometria. O include-guard impede a garra de renderizar sozinha.
//  Exportacao: render (F6) -> "Export as STL".
// ============================================================================

GARRA_AS_LIBRARY = true;          // suprime o render proprio do garra.scad
include <garra.scad>;             // reusa: base() da garra, dedos, sg90_ref, sample, rrect, P, params SG90

/* [ Selecao de peca p/ render/export ] */
show = "assembly";  // [assembly, arm_base, arm_link, garra_base, driver_finger, follower_finger, print_plate]

/* [ Qualidade ] */
$fn = 64;

// ---------------------------------------------------------------------------
//                                PARAMETROS DO BRACO
// ---------------------------------------------------------------------------

/* [ Ombro e elo ] */
arm_link_len    = 72.0;   // comprimento do elo (eixo do ombro -> punho)
shoulder_axis_h = 50.0;   // altura do eixo do ombro acima da mesa
shoulder_pose   = 20;     // angulo do elo no preview (0 = horizontal, + sobe)
link_w          = 16.0;   // largura do elo
link_th         = 7.0;    // espessura (altura impressa) do elo

/* [ Base e yoke (suporte do ombro) ] */
base_w_half     = 30.0;   // meia-largura da base
base_d_half     = 34.0;   // meia-profundidade da base
plate_th        = 4.0;    // espessura da placa da base
wall_t          = 4.0;    // espessura das paredes do yoke
yoke_gap        = 22.0;   // vao interno entre as paredes (precisa > link_w)
axis_cap_r      = 9.0;    // raio do topo arredondado das paredes (sobre o eixo)
idler_d         = 4.0;    // pino coaxial de apoio do elo (parede direita)

/* [ Acoplamento ao horn do servo 1 ] */
horn_bore_d     = shaft_d;   // furo do eixo no hub do elo (herdado da garra)
horn_screw_d    = 2.2;       // 2 furos p/ parafusar o elo no horn redondo

/* [ LED de status (opcional, na base) ] */
show_led_holder = true;
led_d           = 5.4;    // furo do LED de 5mm

// ---------------------------------------------------------------------------
//                          GRANDEZAS DERIVADAS
// ---------------------------------------------------------------------------
wall_x   = yoke_gap/2 + wall_t/2;        // centro X de cada parede do yoke
// deslocamento p/ encaixar a cauda da garra no punho do elo
hand_y   = arm_link_len - by0;           // by0 vem da garra (cauda traseira)

// ---------------------------------------------------------------------------
//                          BASE + YOKE (suporte do ombro)
// ---------------------------------------------------------------------------
module yoke_wall() {
    // parede no plano YZ (espessura wall_t em X), com topo arredondado no eixo
    union() {
        translate([-wall_t/2, -axis_cap_r, 0])
            cube([wall_t, axis_cap_r*2, shoulder_axis_h]);
        translate([0, 0, shoulder_axis_h])
            rotate([0, 90, 0]) cylinder(r = axis_cap_r, h = wall_t, center = true);
    }
}

module arm_base() {
    difference() {
        union() {
            // placa da base (topo em z = plate_th)
            rrect(-base_w_half, -base_d_half, base_w_half, base_d_half, plate_th, 5);
            // duas paredes do yoke
            for (s = [-1, 1]) translate([s * wall_x, 0, 0]) yoke_wall();
        }
        // furo do eixo do servo 1 na parede ESQUERDA (passagem do horn)
        translate([-wall_x - 1, 0, shoulder_axis_h])
            rotate([0, 90, 0]) cylinder(d = shaft_d + 6, h = wall_t + 2);
        // furos da flange do servo 1 (par vertical) - parede esquerda
        for (s = [-1, 1])
            translate([-wall_x - 1, 0, shoulder_axis_h + s * screw_span/2])
                rotate([0, 90, 0]) cylinder(d = screw_d, h = wall_t + 2);
        // furo do pino idler na parede DIREITA
        translate([wall_x - 1, 0, shoulder_axis_h])
            rotate([0, 90, 0]) cylinder(d = idler_d + 0.4, h = wall_t + 2);
        // furo do LED de status na frente da base
        if (show_led_holder)
            translate([base_w_half - 8, base_d_half - 7, -1])
                cylinder(d = led_d, h = plate_th + 2);
        // rebaixo/etiqueta
        translate([0, -base_d_half + 7, plate_th - 0.6])
            linear_extrude(1.2)
                text("BRACO", size = 5, halign = "center", valign = "center",
                     font = "Arial:style=Bold");
    }
    // pino idler solido apontando p/ dentro (-X) da parede direita
    translate([wall_x, 0, shoulder_axis_h])
        rotate([0, -90, 0]) cylinder(d = idler_d, h = wall_t + 3);
}

// ---------------------------------------------------------------------------
//                          ELO (braco) - gira sobre o eixo X do ombro
//  Frame local: hub em y=0; estende-se p/ +Y ate o punho (y = arm_link_len).
//  Espessura em Z (impresso deitado); furo do eixo passa em X pelo hub.
// ---------------------------------------------------------------------------
module arm_link() {
    difference() {
        union() {
            // viga afilada
            hull() {
                cylinder(d = link_w + 4, h = link_th);                 // hub do ombro
                translate([0, arm_link_len, 0]) cylinder(d = link_w*0.85, h = link_th);
            }
        }
        // furo do eixo do ombro (passa em X pelo hub)
        translate([-link_w, 0, link_th/2]) rotate([0, 90, 0])
            cylinder(d = horn_bore_d, h = 2*link_w);
        // 2 furos p/ parafusar o elo no horn (na face esquerda do hub)
        for (s = [-1, 1])
            translate([-link_w/2 - 0.5, 0, link_th/2 + s*6]) rotate([0, 90, 0])
                cylinder(d = horn_screw_d, h = link_w*0.6);
        // padrao de fixacao da GARRA no punho (furos em Z, casa com a base da garra)
        translate([0, arm_link_len, -1]) cylinder(d = arm_bore, h = link_th + 2);
        for (s = [-1, 1])
            translate([s * arm_pattern/2, arm_link_len, -1])
                cylinder(d = arm_screw_d, h = link_th + 2);
        // aligeiramento
        for (i = [1 : 3])
            translate([0, arm_link_len * i/4, -1]) cylinder(d = link_w*0.32, h = link_th + 2);
    }
}

// ---------------------------------------------------------------------------
//                          MAO (garra) - wrapper de reuso
// ---------------------------------------------------------------------------
module gripper_hand() {
    // a montagem da garra (base + servo 2 + dedos + amostra) ja validada
    assembly();
}

// ---------------------------------------------------------------------------
//                          MONTAGEM COMPLETA (preview)
// ---------------------------------------------------------------------------
module arm_assembly() {
    color([0.82, 0.82, 0.86]) arm_base();

    // servo 1 (ombro) na parede esquerda, eixo horizontal (+X)
    translate([-wall_x, 0, shoulder_axis_h]) rotate([0, 90, 0]) sg90_ref();

    // elo + mao giram juntos sobre o eixo do ombro
    translate([0, 0, shoulder_axis_h]) rotate([shoulder_pose, 0, 0]) {
        color([0.93, 0.55, 0.10]) arm_link();
        // garra encaixada no punho (cauda no punho, dedos seguem +Y), sobre o elo
        translate([0, hand_y, link_th]) gripper_hand();
    }
}

// ---------------------------------------------------------------------------
//                          LAYOUT DE IMPRESSAO
// ---------------------------------------------------------------------------
module arm_print_plate() {
    arm_base();
    translate([0, base_d_half + 14, 0]) arm_link();
    translate([-40, base_d_half + 14, 0]) driver_finger();
    translate([-58, base_d_half + 14, 0]) follower_finger();
    translate([45, base_d_half + 30, 0]) base();     // base da garra
}

// ---------------------------------------------------------------------------
//                          DISPATCH
// ---------------------------------------------------------------------------
if      (show == "assembly")        arm_assembly();
else if (show == "arm_base")        arm_base();
else if (show == "arm_link")        arm_link();
else if (show == "garra_base")      base();              // base da garra (reuso)
else if (show == "driver_finger")   driver_finger();     // dedo motor (reuso)
else if (show == "follower_finger") follower_finger();   // dedo seguidor (reuso)
else if (show == "print_plate")     arm_print_plate();
else                                arm_assembly();
