class BusStopUtils {
  const BusStopUtils._();

  static String resolveName(int stopId) => _busStopNames[stopId] ?? '';

  static const _busStopNames = {
    105: 'Fátima',
    8: 'Arcos de la Frontera 1ª',
    9: 'Arcos de la Frontera 2ª',
    289: 'Virgen de Fátima 1ª',
    290: 'Virgen de Fátima 2ª',
    45: 'Carlos III (Blas Infante)',
    358: 'Cinco Caballeros 1ª',
    359: 'Cinco Caballeros 2ª',
    81: 'Sagunto (Centro Salud) D.C.',
    178: 'Marrubial (Padres de Gracia)',
    263: 'San Lorenzo',
    245: 'Realejo',
    277: 'San Pablo',
    456: 'Claudio Marcelo (Tendillas)',
    83: 'Diario Córdoba',
    261: 'San Fernando',
    326: 'El Potro (la Ribera)',
    170: 'Cuesta de la Pólvora',
    491: 'Puerta Nueva',
    17: 'Avda. Barcelona D.C.',
    179: 'Marrubial (Puerta Plasencia)',
    142: 'Agrupación Córdoba',
    304: 'Agrupación Córdoba (Iglesia)',
    67: 'Guaraní',
    228: 'Mahatma Gandhi',
    194: 'Ntra. Sra. De la Merced',
    87: 'Fátima (Dr.Nevado del Rey)',
    104: 'Fátima (Arcos de la Frontera)',
    151: 'Platero Pedro de Bares',
    256: 'Sagunto',
    173: 'Sagunto (Los Apóstoles)',
    113: 'Ollerías D.C.',
    260: 'Ollerías (San Cayetano)',
    64: 'Colón Norte',
    117: 'Ronda Tejares (Doce Octubre)',
    68: 'Ronda Tejares (Gran Capitán)',
    250: 'República Argentina',
    145: 'Glorieta Media Luna',
    126: 'Vallellano (Ministerios)',
    323: 'Puerta Sevilla',
    7: 'Pintor Espinosa (Custodios)',
    209: 'Pintor Espinosa',
    86: 'Doctor Julián R. Martín',
    139: 'Hospital Provincial D.R.Sofía',
    55: 'Colegios Mayores D.R.Sofía',
    143: 'Hospital Reina Sofía',
    56: 'Colegios Mayores',
    140: 'Hospital Provincial',
    185: 'Menéndez Pidal',
    152: 'Instituto Séneca',
    240: 'Puerta Sevilla D.C.',
    283: 'Vallellano (Comisaría)',
    74: 'Glorieta Cruz Roja',
    237: 'Paseo Victoria (Puerta Gallegos)',
    239: 'Paseo Victoria (Ronda Tejares)',
    116: 'Ronda Tejares (Cruz Conde)',
    58: 'Colón Este',
    259: 'Ollerías (Puerta Colodro)',
    112: 'Ollerías',
    43: 'Caravaca de la Cruz',
    80: 'Sagunto (Centro Salud)',
    172: 'Fernando IV (Sagunto)',
    106: 'Fernando IV',
    44: 'Carlos III',
    2006: 'Esc. Gabriela Mistral',
    2007: 'Esc. Yolanda Oreamuno',
    2008: 'Francisco Gracia Trenas',
    2009: 'Francisco Gracia Trenas 2ª',
    426: 'Albaida',
    402: 'Ctra. Trassierra (Anna Pavlova) D.C',
    315: 'Isla Formentera',
    329: 'Isla Mallorca (Juzgados) D.C',
    330: 'Arroyo del Moro D.C.',
    99: 'Escritor Mercado Solís D.C.',
    342: 'Francisco Azorín',
    442: 'RENFE-Est.Buses OESTE',
    51: 'Avda. América',
    131: 'Gran Capitán',
    459: 'Ronda Tejares (Calle Caño)',
    477: 'Alfaros (Juan Rufo)',
    517: 'Alfaros (Alfonso XIII)',
    271: 'Claudio Marcelo (Tendillas)',
    360: 'Camino de la Barca',
    69: 'Periodista Eduardo Baro',
    327: 'Periodista José Luis De Córdoba',
    361: 'Calderón de la Barca',
    363: 'Virgen de la Fuensanta',
    357: 'San Martín de Porres',
    295: 'Virgen del Mar',
    4: 'Alonso G. Figueroa',
    269: 'Sta. Emilia de Rodat (Gago Jiménez)',
    208: 'Ministerio de la Vivienda',
    381: 'Virgen de la Fuensanta 1ª',
    443: 'Virgen de la Fuensanta 2ª',
    171: 'Campo Madre de Dios ( Agustín Moreno)',
    93: 'El Potro (La Ribera) D.C.',
    282: 'Puerta del Puente',
    2019: 'Alcázar de los Reyes Cristianos',
    236: 'Paseo Victoria (Puerta Gallegos)',
    380: 'Avda. Cervantes',
    207: 'Glorieta Tres Culturas',
    313: 'RENFE - Est.Buses',
    435: 'Huerta del Recuero',
    98: 'Escritor Mercado Solís',
    325: 'Arroyo del Moro',
    401: 'Ctra. Trassierra (Anna Pavlova)',
    2020: 'Ctra. Trassierra (San Rafael de la Albaida)',
    494: 'San Rafael de la Albaida',
    2010: 'José Aguilar de Dios',
    2011: 'Huerta Santa Isabel',
    107: 'Fidiana',
    108: 'Avda.  Libia (Tomás Sánchez)',
    36: 'Avda. de Libia (El Cairo)',
    410: 'Avda.de Libia (Correos)',
    154: 'Jesús Rescatado',
    285: 'Jesús Rescatado (Viñuela)',
    61: 'Colón Norte',
    118: 'Ronda Tejares (Doce Octubre)',
    88: 'Ronda de Tejares (Gran Capitán)',
    222: 'Vía Augusta',
    487: 'Centro Sanitario Castilla del Pino',
    427: 'Cantábrico',
    428: 'Isla Fuerteventura',
    429: 'Isla Gomera',
    302: 'Paseo de los Verdiales (Miralbaida)',
    187: 'Miralbaida',
    177: 'María La Talegona',
    413: 'Paseo de los Verdiales D.C.',
    346: 'Isla Graciosa',
    355: 'Isla Fuerteventura D.C.',
    390: 'Cantábrico D.C.',
    488: 'Centro Sanitario Castilla del Pino DC',
    444: 'Vía Augusta D.C.',
    16: 'Avda. Barcelona',
    445: 'Avda. de Libia (Cementerio)',
    321: 'Avda. de Libia',
    144: 'Hospital Reina Sofía',
    141: 'José de Tapia (Hospital Provincial)',
    211: 'Pintor Espinosa (Zurbarán)',
    210: 'Pintor Espinosa D.C.',
    292: 'Virgen de los Dolores D.C.',
    334: 'Parque de las Avenidas D.C.',
    12: 'Avda. Aeropuerto (Polideportivo)',
    156: 'Avda. Aeropuerto (Ministerios)',
    73: 'Glorieta Cruz Roja',
    76: 'Ctra. Trassierra 1ª',
    78: 'Ctra. Trassierra 2ª',
    409: 'Ctra. Trassierra 3ª',
    314: 'Cañito Bazán',
    311: 'Dolores Ibárruri 1ª',
    312: 'Dolores Ibárruri 2ª',
    229: 'Poeta Emilio Prados',
    502: 'Avda. Arruzafilla',
    503: 'Esc. Fernández Márquez 1ª',
    510: 'Esc. Fernández Márquez 2ª',
    286: 'Virgen Angustias 1ª D.C.',
    287: 'Virgen Angustias 2ª D.C.',
    14: 'Avda. Almogávares D.C.',
    157: 'La Higuera',
    159: 'La Palmera',
    504: 'Avda. Arruzafilla D.C.Sanitaria',
    424: 'María La Judía 1ª',
    425: 'María La Judía 2ª',
    449: 'María Zambrano',
    79: 'Ctra. Trassierra 1ª  D.C.',
    189: 'Ctra. Trassierra 2ª D.C.',
    77: 'Crta. Trassierra 3ª D.C.',
    246: 'RENFE- Est. Buses',
    10: 'Avda. Aeropuerto 1ª',
    11: 'Avda. Aeropuerto 2ª',
    206: 'Parque Las Avenidas',
    291: 'Virgen de los Dolores',
    97: 'Escritor Carrillo Lasso',
    63: 'Colón Norte',
    343: 'Ronda Tejares (Gran Capitán)',
    251: 'República Argentina',
    146: 'Glorieta Media Luna',
    241: 'Puerta Sevilla D.Sector Sur',
    519: 'Avda. del Corregidor',
    214: 'Avda. Granada (Plaza Andalucía)',
    91: 'Avda. Granada',
    46: 'Carretera  de Granada',
    164: 'Libertadores Carrera y O´Higgins 1ª',
    331: 'Libertadores Carrera y O´Higgins 2ª',
    120: 'General Lázaro Cárdenas 1ª',
    121: 'General Lázaro Cárdenas 2ª',
    168: 'Libertador Simón Bolívar',
    434: 'Libertador Joaquín Da Silva (colegio)',
    400: 'Motril',
    47: 'Carretera de Granada D.C.',
    92: 'Avda. Granada D.C.',
    215: 'Avda. Granada (Plaza Andalucía) D.C.',
    520: 'Avda. del Corregiddor DC',
    217: 'Plaza de Cañero',
    298: 'Virgen Milagrosa 1ª D.C.',
    300: 'Virgen Milagrosa 2ª D.C.',
    49: 'Virgen Milagrosa (Cementerio) D.C.',
    62: 'Colón Norte',
    335: 'Ronda Tejares (Gran Capitán)',
    421: 'Costa del Sol',
    536: 'Antonio Maura (Gran Vía Parque)',
    135: 'Guerrita 1ª',
    136: 'Guerrita 2ª',
    514: 'Conde Zamora (E.P.Bazán)',
    513: 'Hospital Quirón',
    515: 'Escritora Elena Quiroga',
    542: 'Avda. Manolete (Conde Zamora)',
    301: 'Avda. Manolete 1ª',
    27: 'Avda. Manolete 2ª',
    71: 'Costa del Sol DC',
    235: 'Paseo Victoria (Puerta Gallegos)',
    255: 'Ronda Tejares (Bulevar Gran Capitán)',
    40: 'Campo Madre de Dios',
    48: 'Virgen Milagrosa (Cementerio)',
    299: 'Virgen Milagrosa 1ª',
    297: 'Virgen Milagrosa 2ª',
    268: 'Sta. Emilia de Rodat',
    72: 'Cruz de Juárez',
    288: 'Virgen Angustias 3ª D.C.',
    447: 'Fuente de la Salud D.C.',
    446: 'Avda. Al-Nasir',
    84: 'Diputación',
    200: 'Medina Azahara 1ª',
    181: 'Medina Azahara 2ª',
    319: 'Huerta de la Marquesa',
    30: 'Barriada Occidente',
    95: 'Electromecánicas (Miralbaida)',
    186: 'Miralbaida (Paseo de los Verdiales)',
    451: 'Paseo de los Verdiales',
    29: 'Ingeniero Benito Arana (Parque Azahara)',
    204: 'Ingeniero Alfonso de Churruca',
    161: 'Ingeniero Antonio Carbonell',
    162: 'Las Palmeras',
    505: 'Parque Joyero',
    399: 'Carretera de Palma de Río',
    205: 'Parque Azahara',
    96: 'Electromecánicas',
    31: 'Barriada Occidente D.C.',
    320: 'Huerta de la Marquesa D.C.',
    182: 'Medina Azahara 1ª D.C.',
    284: 'Medina Azahara 2ª D.C.',
    115: 'Ronda Tejares (Cruz Conde)',
    66: 'Colón Oeste',
    436: 'Avda. de los Piconeros',
    416: 'Fuente de la Salud',
    417: 'Virgen de las Angustias 1ª',
    418: 'Virgen de las Angustias 2ª',
    28: 'Avda. del Mediterráneo',
    109: 'Figueroa (Cine)',
    110: 'Figueroa (Club)',
    192: 'Músico Tomás de Victoria D.C.',
    129: 'Goya 1ª',
    130: 'Goya 2ª',
    345: 'Llanos del Pretorio D.C.',
    379: 'Úbeda',
    431: 'Algeciras 1ª',
    430: 'Algeciras 2ª',
    432: 'Libertador J. R. Mora 1ª',
    433: 'Libertador J. R. Mora 2ª',
    163: 'Libertador Andrés de Santa Cruz',
    165: 'Libertador J.R.Mora 1ª D.C.',
    166: 'Libertador J.R.Mora 2ª D.C.',
    167: 'Libertador Joaquín Da Silva',
    169: 'Loja',
    221: 'Plaza del Mediodía',
    153: 'Jerez',
    6: 'Huelva (Ambulatorio)',
    216: 'Plaza Andalucía',
    310: 'Paseo Victoria (Ronda Tejares)',
    354: 'Llanos del Pretorio',
    193: 'Nogal',
    57: 'Colombia',
    419: 'Tenor Pedro Lavirgen 1ª',
    191: 'Músico Tomás de Victoria',
    450: 'Isla Mallorca (Juzgados)',
    111: 'Figueroa (Instituto)',
    248: 'RENFE- Est. Buses',
    338: 'Gran Capitán',
    65: 'Colón Oeste',
    306: 'Avda. Brillante (Las Acacias)',
    32: 'Avda. Brillante (E.Fdez.Márquez)',
    38: 'Avda. Brillante (Cámping)',
    231: 'Avda. Brillante (A.Calasancio)',
    322: 'Avda. Brillante (Virgen del  Valle)',
    137: 'Avda. Brillante (H.S.Juan de Dios)',
    280: 'Avda. Brillante (Toledo)',
    1: 'Avda. Brillante (A. Núñez)',
    33: 'Avda. Brillante (Mayoral)',
    149: 'Huerta Los Arcos',
    242: 'Quitapesares',
    89: 'El Cerrillo',
    339: 'Huerta de San Antón',
    174: 'Hospital Los Morales',
    340: 'Huerta de San Antón D.C.',
    90: 'El Cerrillo D.C.',
    243: 'Quitapesares D.C.',
    150: 'Huerta Los Arcos D.C.',
    34: 'Avda. Brillante (Mayoral) D.C.',
    2: 'Avda. Brillante (A. Núñez) D.C.',
    281: 'Avda. Brillante (Toledo) D.C.',
    138: 'Avda. Brillante (H.S.Juan de Dios)  D.C.',
    238: 'Avda. Brillante (Virgen del Valle)  D.C.',
    233: 'Avda. Brillante (A.Calasancio) D.C.',
    39: 'Avda. Brillante (Cámping) D.C.',
    35: 'Avda. Brillante (E.Fdez.Márquez) D.C.',
    148: 'Avda . Brillante (Goya)',
    70: 'Ronda Tejares (Gran Capitán)',
    50: 'Avda. Cervantes',
    249: 'RENFE- Est. Buses',
    232: 'Avda. Calasancio (Brillante)',
    21: 'Avda. Calasancio 1ª',
    23: 'Avda. Calasancio 2ª',
    123: 'Glorieta Calasancio',
    264: 'Sansueña (Eucalipto)',
    266: 'Sansueña 1ª',
    308: 'Sansueña 2ª',
    125: 'Glorieta Castilleja',
    213: 'Mayoral',
    190: 'Músico Guerrero 1ª',
    309: 'Músico Guerrero 2ª',
    212: 'Músico Guerrero 3ª',
    265: 'Sansueña (Eucalipto) D.C.',
    155: 'Juan Ochoa',
    257: 'Saldaña 1ª',
    258: 'Saldaña 2ª',
    75: 'Ctra. Calasancio',
    124: 'Glorieta Calasancio D.C.',
    24: 'Avda. Calasancio 1ª. D.C.',
    22: 'Avda. Calasancio 2ª D.C.',
    415: 'Glorieta Alholva',
    406: 'Rosa de Siria D. C.',
    219: 'Plaza de Bellavista',
    101: 'Escultor Ramón Barba 1ª D.C.',
    103: 'Escultor Ramón Barba 2 ª D.C.',
    347: 'Cruz de Juárez D.C.',
    353: 'Miraflores',
    351: 'Avda. Campo de la Verdad',
    223: 'Avda.Cádiz (Plaza Santa Teresa)',
    19: 'Avda. Cádiz',
    18: 'Avda. Cádiz (Plaza de Andalucía)',
    234: 'Plaza Mediodía',
    20: 'Avda. Cádiz D.C',
    224: 'Avda.Cádiz (Plaza Santa Teresa )  D.C.',
    350: 'Avda. Campo de la Verdad (Gasolinera)',
    352: 'Miraflores D.C.',
    452: 'Ribera (San Fernando)',
    267: 'Santa Rosa',
    13: 'Avda. Almogávares',
    102: 'Escultor Ramón Barba 1ª',
    100: 'Escultor Ramón Barba 2ª',
    198: 'Madres Escolapias',
    199: 'Deán Francisco Javier',
    404: 'Rosa de Siria',
    60: 'Colón Norte',
    420: 'Tenor Pedro Lavirgen',
    495: 'Músico Cristóbal de Morales',
    225: 'Poeta Antonio Machado',
    94: 'El Tablero (Circuito)',
    534: 'Poeta Juan Ramón Jiménez',
    522: 'Turruñuelos',
    528: 'Abderramán I',
    523: 'El Manantial',
    530: 'Camino de la Albaida',
    524: 'Camino del Patriarca',
    507: 'Barón de Fuente Quintos',
    202: 'Parador La Arruzafa',
    183: 'Mejorana',
    525: 'Cantueso (Ctra. de las Ermitas)',
    521: 'Ctra. de las Ermitas (Cuevas de Roma)',
    341: 'Carretera de las Ermitas',
    386: 'Poeta Jorge Guillén',
    387: 'Arrayanes',
    134: 'Glorieta Alba',
    160: 'Escudería',
    82: 'Cuevas de la Gran Roma',
    54: 'San Juan Bautista (La Salle)',
    203: 'Parador La Arruzafa D.C.',
    508: 'Barón de Fuente Quintos 1ª',
    531: 'Camino de la Albaida (Sefardíes)',
    526: 'Camino de la Albaida DC',
    527: 'El Manantial DC',
    529: 'Abderramán I DC',
    509: 'Barón de Fuente Quintos 2ª',
    535: 'Poeta Juan Ramón Jiménez DC',
    227: 'Poeta Juan Ramón Jiménez (Circuito)',
    226: 'Poeta Antonio Machado D.C.',
    230: 'Poeta Emilio Prados D.C.',
    492: 'Músico Cristóbal de Morales DC',
    448: 'Tenor Pedro Lavirgen 2ª',
    437: 'Paco León',
    398: 'Zafiro (Central de taxis)',
    37: 'Calderón de la Barca D.C.Sanitaria',
    324: 'El Pocito',
    132: 'Periodista Ricardo Rodríguez 1ª',
    382: 'Periodista Ricardo Rodríguez 2ª',
    26: 'Arenal  (D.Campo de la Verdad)',
    176: 'Marbella',
    175: 'Marbella (Motril)',
    370: 'L. Simón Bolívar 1ª D.C.Sanitaria',
    270: 'L. Simón Bolívar 2ª D.C.Sanitaria',
    383: 'Libertador H.Costilla D.C.Sanitaria',
    307: 'Libertador Hidalgo y Costilla',
    52: 'Ciudad  de Carmona 1ª',
    53: 'Ciudad  de Carmona 2ª',
    25: 'Avda. Diputación',
    42: 'Arenal D.Fidiana',
    384: 'P. José Luis de Córdoba (Arenal)',
    218: 'Ministerio de la Vivienda D.Fidiana',
    388: 'Pablo Ruiz Picasso',
    478: 'Rodríguez Marín',
    479: 'Plaza de la Corredera',
    480: 'Plaza Almagra',
    481: 'Iglesia de San Pedro',
    482: 'Plaza Vizconde de Miranda',
    483: 'Plaza Conde de  Gavia',
    438: 'Puerta Nueva',
    484: 'Plaza de la Magdalena',
    485: 'Ronda de Andújar (c/ Escañuela)',
    439: 'Jesús del Calvario',
    486: 'San Juan de Letrán',
    461: 'Padres de Gracia',
    472: 'Mª Auxiliadora',
    473: 'Plaza Juan Bernier',
    474: 'Hermanos López Diéguez',
    475: 'Palacio de Viana',
    476: 'Iglesia de Santa Marina',
    493: 'Puerta del Colodro',
    567: 'Huerta del Hierro',
    569: 'Huerta del Hierro (Maestre Escuela)',
    572: 'Maestre Escuela 1ª',
    574: 'Maestre Escuela 2ª',
    576: 'Maestre Escuela 3ª',
    578: 'Cursillos de Cristiandad',
    579: 'E.Fdez. Márquez (M. de Falla)',
  };
}
