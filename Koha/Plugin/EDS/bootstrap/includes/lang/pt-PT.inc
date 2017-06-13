/*[% EDSLANG = {
    home_breadcrumb    									= 'Início'
	eds_results_TT_no_results   						= 'Não foram encontrados resultados!'
	eds_results_TT_results_returned_msg					= 'Resultados da sua pesquisa'
    eds_results_TT_results_msg							= 'resultados.'
    eds_results_TT_did_you_mean							= 'Quis dizer:'
    eds_results_TT_title_attr							= 'Ver detalhes para este título'
    eds_results_TT_links								= 'Links:'
    eds_results_TT_links_html							= 'Texto completo em HTML'
    eds_results_TT_links_pdf							= 'exto completo em PDF'
    eds_results_TT_links_ebook							= 'Texto completo em eBook'
    eds_results_TT_actions								= 'Ações:'
    eds_results_TT_place_reserve						= 'Reservar'
    eds_results_TT_save_to_list							= 'Guardar na lista'
    eds_results_TT_in_cart								= 'No seu carrinho'
    eds_results_TT_remove_cart							= '(remover)'
    eds_results_TT_add_cart								= 'Adicionar ao carrinho'
	eds_results_TT_login_msg							= 'Faça login para ver este resultado.'
    eds_results_TT_annosuggestions						= 'Não encontrou o que procura?'
    eds_results_TT_annosuggestions_makea				= 'Faça uma'
    eds_results_TT_annosuggestions_purchase				= 'Sugestão de compra'
    
	eds_detail_TT_details_for							= 'Detalhes para:'
	eds_detail_TT_normal_view							= 'Visualização normal:'
	eds_detail_TT_login_msg								= 'Faça login para ter acesso a este resultado.'
    
    eds_detail_customlinks_INC_html_fulltext			= 'Texto completo em HTML'
    eds_detail_customlinks_INC_pdf_fulltext				= 'Texto completo em PDF'
    eds_detail_customlinks_INC_ebook_fulltext			= 'Texto completo em eBook'
    eds_detail_customlinks_INC_view_in_eds				= 'Visualizar no EDS'
    
    eds_detail_sidebar_INC_print						= 'Imprimir'
    eds_detail_sidebar_INC_in_cart						= 'No seu carrinho'
    eds_detail_sidebar_INC_remove_cart					= '(remover)'
    eds_detail_sidebar_INC_add_cart						= 'Adicionar ao carrinho'
        
	eds_advsearch_TT_breadcrumb_home					= 'Início'
    eds_advsearch_TT_breadcrumb_advanced_search			= 'Pesquisa avançada'
    eds_advsearch_TT_select_field						= 'Selecionar um campo (opcional)'
	eds_advsearch_TT_bool_and							= 'AND'
	eds_advsearch_TT_bool_or							= 'OR'
	eds_advsearch_TT_bool_not							= 'NOT'
    eds_advsearch_TT_opt_add							= 'Adicionar'
    eds_advsearch_TT_opt_remove							= 'Remover'
    eds_advsearch_TT_search_options						= 'Opções de pesquisa'
    eds_advsearch_TT_search_opt_heading					= 'Opções de pesquisa e filtros'
    eds_advsearch_TT_search_opt_modes					= 'Modo de pesquisa'
    eds_advsearch_TT_search_help_title					= 'Insira o texto - frase, parágrafo, ou páginas inteiras. Este modo apenas pesquisa nas bases dados da EBSCO.'
    eds_advsearch_TT_search_help						= 'Sugestão'
    eds_advsearch_TT_limit_legend						= 'Limitar resultados'
	eds_advsearch_TT_date_month							= 'Mês'
	eds_advsearch_TT_date_month_jan						= 'Janeiro'
    eds_advsearch_TT_date_month_feb						= 'Fevereiro'
    eds_advsearch_TT_date_month_mar						= 'Março'
    eds_advsearch_TT_date_month_apr						= 'Abril'
    eds_advsearch_TT_date_month_may						= 'Maio'
    eds_advsearch_TT_date_month_jun						= 'Junho'
    eds_advsearch_TT_date_month_jul						= 'Julho'
    eds_advsearch_TT_date_month_aug						= 'Agosto'
    eds_advsearch_TT_date_month_sep						= 'Setembro'
    eds_advsearch_TT_date_month_oct						= 'Outubro'
    eds_advsearch_TT_date_month_nov						= 'Novembro'
    eds_advsearch_TT_date_month_dec						= 'Dezembro'
    eds_advsearch_TT_date_year							= 'Ano:'
    eds_advsearch_TT_btn_search							= 'Pesquisar'
    eds_advsearch_TT_btn_reset							= 'Limpar'
    

    
    eds_facets_INC_refine_search						= 'Refinar a pesquisa'
    eds_facets_INC_current_search						= 'Pesquisa atual'
	eds_facets_INC_search_term							= 'Termo(s) de pesquisa'
    eds_facets_INC_active_facets						= 'Activar Facetas'
    eds_facets_INC_limit_to								= 'Limitar a:'
    eds_facets_INC_expand_to							= 'Expandir para:'
    
    eds_page_numbers_INC_previous						= 'Anterior'
    eds_page_numbers_INC_next 							= 'Próximo'
    
    eds_publicationexactmatch_INC_full_text_access		= 'Acesso ao Texto completo'
    eds_publicationexactmatch_INC_search_within			= 'Pesquisar em Publicações'
    
    eds_researchstarters_INC_more						= 'Mais.'
    
    eds_resort_form_INC_results_per_page				= 'Resultados por página:'
    eds_resort_form_INC_view							= 'Visualizar:'
    eds_resort_form_INC_view_title						= 'Título'
    eds_resort_form_INC_view_brief						= 'Resumido'
    eds_resort_form_INC_view_detail						= 'Detalhe'
    eds_resort_form_INC_search_mode						= 'Modo pesquisa:'
    eds_resort_form_INC_sort_by							= 'Ordenar por:'
}%]*/
var EDSLANG = {
	eds_koha_lang_id									: 'pt-PT',
	eds_koha_language									: '[%lang%]',
	eds_switch_text										: 'Alterar para Discovery',
	koha_switch_text									: 'Alterar para Catalogo',
	eds_select_text										: "Discovery",
	eds_select_info										: '<h3>Pesquisa EDS</h3>Selecione um termo e digite uma expressão de pesquisa',
	koha_select_info									: '<h3>Pesquisa Koha</h3>Selecione um termo e digite uma expressão de pesquisa',
	search_breadcrumb									: 'Resultados da pesquisa',
	login_to_access										: 'Faça login para ver este resultado.',
	go_to_detail										: 'Ver detalhes',
	more_details										: 'Mais resultados',
	view_more_results									: 'Ver mais resultados',
	more_loading_msg									: 'A carregar. Por favor aguarde...',
	previous_title										: 'Ver anterior',
	previous											: 'Anterior',
	next_title											: 'Ver próximo',
	next												: 'Próximo',
	update_facets										: 'Atualizar',
	basket_loading										: 'A carregar. Por favor aguarde...',
	basket_item_location								: 'Discovery',
	basket_deselect_hold								: 'Desmarcar títulos do Discovery para fazer reserva.',
	basket_deselect_list								: 'Desmarcar títulos do Discovery para adicionar à lista.',
	date_valid_format									: 'Por favor, insira um ano válido no formato YYYY',
	date_invalid										: 'Data inválida. Por favor, insira uma data válida no formato YYYY-MM/YYYY-MM format.\n e.g. 1900-01/2000-12.\n Remover todos os caracteres e pressione Enter para remover o limitador de data.'						
};