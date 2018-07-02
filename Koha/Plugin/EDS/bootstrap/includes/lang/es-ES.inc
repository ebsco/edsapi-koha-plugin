/*[% EDSLANG = {
    home_breadcrumb    									= 'Página principal'
	eds_results_TT_no_results   						= 'Resultados no encontrados!'
	eds_results_TT_results_returned_msg					= 'Tu búsqueda encontrada'
    eds_results_TT_results_msg							= 'resultados.'
    eds_results_TT_did_you_mean							= 'Querías decir:'
    eds_results_TT_title_attr							= 'Ver detalles para este título'
    eds_results_TT_links								= 'Enlaces:'
    eds_results_TT_links_html							= 'Texto Completo en HTML'
    eds_results_TT_links_pdf							= 'Texto Completo en PDF'
    eds_results_TT_links_ebook							= 'Texto Completo en Ebook'
    eds_results_TT_actions								= 'Acciones:'
    eds_results_TT_place_reserve						= 'Reservar'
    eds_results_TT_save_to_list							= 'Guardar en las listas'
    eds_results_TT_in_cart								= 'En tu carpeta'
    eds_results_TT_remove_cart							= '(quitar)'
    eds_results_TT_add_cart								= 'Añadir en tu carpeta'
	eds_results_TT_login_msg							= 'Autenticar para acceder a este resultado.'
    eds_results_TT_annosuggestions						= 'No se ha encontrado lo que estás buscando?'
    eds_results_TT_annosuggestions_makea				= 'Sugerir'
    eds_results_TT_annosuggestions_purchase				= 'sugerir compra'

	eds_detail_TT_details_for							= 'Detalles para:'
	eds_detail_TT_normal_view							= 'Vista general:'
	eds_detail_TT_login_msg								= 'Autenticar para acceder a este resultado.'

    eds_detail_customlinks_INC_html_fulltext			= 'Texto Completo en HTML'
    eds_detail_customlinks_INC_pdf_fulltext				= 'Texto Completo en PDF'
    eds_detail_customlinks_INC_ebook_fulltext			= 'Texto Completo en Ebook'
    eds_detail_customlinks_INC_view_in_eds				= 'Ver en EDS'

    eds_detail_sidebar_INC_print						= 'Imprimir'
    eds_detail_sidebar_INC_in_cart						= 'En tu carpeta'
    eds_detail_sidebar_INC_remove_cart					= '(quitar)'
    eds_detail_sidebar_INC_add_cart						= 'Añadir en tu carpeta'

	eds_advsearch_TT_breadcrumb_home					= 'Página principal'
    eds_advsearch_TT_breadcrumb_advanced_search			= 'Búsqueda avanzada'
    eds_advsearch_TT_select_field						= 'Selecionar un campo (opcional)'
	eds_advsearch_TT_bool_and							= 'AND'
	eds_advsearch_TT_bool_or							= 'OR'
	eds_advsearch_TT_bool_not							= 'NOT'
    eds_advsearch_TT_opt_add							= 'Añadir'
    eds_advsearch_TT_opt_remove							= 'Quitar'
    eds_advsearch_TT_search_options						= 'Opciones de búsqueda'
    eds_advsearch_TT_search_opt_heading					= 'Modos de búsqueda y Ampliadores'
    eds_advsearch_TT_search_opt_modes					= 'Modos de búsqueda'
    eds_advsearch_TT_search_help_title					= 'Escribe todo el texto  - una frase, una oración, párrafo, o toda una página. Este modo busca solo en bases datos de EBSCO.'
    eds_advsearch_TT_search_help						= 'Sugerir'
    eds_advsearch_TT_limit_legend						= 'Limitar tus resultados'
	eds_advsearch_TT_date_month							= 'Mes'
	eds_advsearch_TT_date_month_jan						= 'enero'
    eds_advsearch_TT_date_month_feb						= 'febrero'
    eds_advsearch_TT_date_month_mar						= 'marzo'
    eds_advsearch_TT_date_month_apr						= 'abril'
    eds_advsearch_TT_date_month_may						= 'mayo'
    eds_advsearch_TT_date_month_jun						= 'junio'
    eds_advsearch_TT_date_month_jul						= 'julio'
    eds_advsearch_TT_date_month_aug						= 'agosto'
    eds_advsearch_TT_date_month_sep						= 'septiembre'
    eds_advsearch_TT_date_month_oct						= 'octubre'
    eds_advsearch_TT_date_month_nov						= 'noviembre'
    eds_advsearch_TT_date_month_dec						= 'diciembre'
    eds_advsearch_TT_date_year							= 'año:'
    eds_advsearch_TT_btn_search							= 'Buscar'
    eds_advsearch_TT_btn_reset							= 'Resetear'



    eds_facets_INC_refine_search						= 'Definir tu búsqueda'
    eds_facets_INC_current_search						= 'Búsqueda actual'
	eds_facets_INC_search_term							= 'Término(s) de búsqueda'
    eds_facets_INC_active_facets						= 'Facetas activas'
    eds_facets_INC_limit_to								= 'Limitar a:'
    eds_facets_INC_expand_to							= 'Ampliar a:'

    eds_page_numbers_INC_previous						= 'Anterior'
    eds_page_numbers_INC_next 							= 'Posterior'

    eds_publicationexactmatch_INC_full_text_access		= 'Acceso a Texto completo'
    eds_publicationexactmatch_INC_search_within			= 'Buscar dentro de la Publicación'

    eds_researchstarters_INC_more						= 'Más.'

    eds_resort_form_INC_results_per_page				= 'Resultados por pagina:'
    eds_resort_form_INC_view							= 'Vista:'
    eds_resort_form_INC_view_title						= 'Título'
    eds_resort_form_INC_view_brief						= 'Resumen'
    eds_resort_form_INC_view_detail						= 'Detallado'
    eds_resort_form_INC_search_mode						= 'Modo de búsqueda:'
    eds_resort_form_INC_sort_by							= 'Ordenar por:'
}%]*/
var EDSLANG = {
	eds_koha_lang_id									: 'es-ES',
	eds_koha_language									: '[%lang%]',
	eds_switch_text										: 'Cambiar Discovery',
	koha_switch_text									: 'Cambiar a Catálogo',
	eds_select_text										: "Discovery",
	koha_select_text                                    : 'Catálogo',
	eds_select_info										: '<h3>Buscar en EDS</h3>Seleccionar un ítem conocido y escribir un término de búsqueda',
	koha_select_info									: '<h3>Buscar en Koha</h3>Seleccionar un ítem conocido y escribir un término de búsqueda',
	search_breadcrumb									: 'Resultados de la búsqueda',
	pfi_atoz_bar										: 'Browse by Journal Title:',
	login_to_access										: 'Autenticar para acceder a este resultado.',
	go_to_detail										: 'Ir al detalle',
	more_details										: 'Más resultados',
	view_more_results									: 'Ver más resultados',
	more_loading_msg									: 'Cargando. Por favor espere...',
	previous_title										: 'Ver anterior',
	previous											: 'Anterior',
	next_title											: 'Ver siguiente',
	next												: 'Siguiente',
	update_facets										: 'Actualizar',
	basket_loading										: 'Cargando ítems. Por favor espere...',
	basket_item_location								: 'Discovery',
	basket_deselect_hold								: 'Deselecionar títulos desde Discovery para reservar.',
	basket_deselect_list								: 'Deselecionar títulos desde Discovery para anãdir en la lista.',
	date_valid_format									: 'Por favor inserte formato de año correcto YYYY',
	date_invalid										: 'Fecha inválida. Por favor inserte formato de fecha válido YYYY-MM/YYYY-MM.\n ej. 1900-01/2000-12.\n Borrar todos los caracteres y presionar ENTER para borrar el limitador de fecha.'
};
