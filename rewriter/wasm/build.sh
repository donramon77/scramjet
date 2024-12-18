#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

# Check for cargo and wasm-bindgen
which cargo wasm-bindgen wasm-opt &> /dev/null || {
	echo "Please install cargo, wasm-bindgen, and wasm-opt! Exiting..."
	exit 1
}

WBG="wasm-bindgen 0.2.99"
if ! [[ "$(wasm-bindgen -V)" =~ ^"$WBG" ]]; then
	echo "Incorrect wasm-bindgen-cli version: '$(wasm-bindgen -V)' != '$WBG'"
	exit 1
fi

if ! [ "${RELEASE:-0}" = "1" ]; then
	: "${WASMOPTFLAGS:=-g}"
	: "${FEATURES:=debug}"
else
	: "${WASMOPTFLAGS:=}"
	: "${FEATURES:=}"
fi

(
	export RUSTFLAGS='-C target-feature=+atomics,+bulk-memory,+simd128 -Zlocation-detail=none -Zfmt-debug=none'
	cargo build --release --target wasm32-unknown-unknown \
		-Z build-std=panic_abort,std -Z build-std-features=panic_immediate_abort,optimize_for_size \
		--no-default-features --features "$FEATURES"
)
wasm-bindgen --target web --out-dir out/ ../target/wasm32-unknown-unknown/release/wasm.wasm

sed -i 's/import.meta.url/""/g' out/wasm.js

cd ../../

wasm-snip rewriter/wasm/out/wasm_bg.wasm -o rewriter/wasm/out/wasm_snipped.wasm \
	-p 'oxc_regular_expression::.*' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_non_array_type' \
	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::parse_declaration' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_import_type' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_operator_or_higher' \
	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::parse_ts_interface_declaration' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_mapped_type' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_index_signature_declaration' \
	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::parse_ts_import_equals_declaration' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_or_type_predicate' \
	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::parse_ts_namespace_or_module_declaration_body' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_implements_clause' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_intersection_type_or_higher' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_type_name' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_literal_type_node' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_asserts_type_predicate' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_tuple_element_type' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_arguments_of_type_reference' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_call_signature_member' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::is_start_of_type' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_this_type_predicate' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_query' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_reference' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_operator' \
	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_literal' \
	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::is_at_enum_declaration' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_element' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_identifier' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_element_name' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_children' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_fragment' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_expression_container' \
	'oxc_parser::jsx::<impl oxc_parser::ParserImpl>::parse_jsx_expression'
#
#	these are confirmed to break oxc
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_type' \
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_type_arguments_in_expression' \
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_type_parameters' \
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_class_element_modifiers' \
#	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::eat_decorators' \
#	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::is_nth_at_modifier' \
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::try_parse_type_arguments' \
#	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::is_at_ts_index_signature_member' \
#	'oxc_parser::ts::types::<impl oxc_parser::ParserImpl>::parse_ts_return_type_annotation' \
#	'oxc_parser::ts::statement::<impl oxc_parser::ParserImpl>::parse_ts_type_annotation' \


(
	G="--generate-global-effects"
	# shellcheck disable=SC2086
	time wasm-opt $WASMOPTFLAGS \
		rewriter/wasm/out/wasm_snipped.wasm -o rewriter/wasm/out/optimized.wasm \
		--converge -tnh --enable-threads --enable-bulk-memory --enable-simd \
		$G --type-unfinalizing $G --type-ssa $G -O4 $G --flatten $G --rereloop $G -O4 $G -O4 $G --type-merging $G --type-finalizing $G -O4 \
		$G --type-unfinalizing $G --type-ssa $G -Oz $G --flatten $G --rereloop $G -Oz $G -Oz $G --type-merging $G --type-finalizing $G -Oz \
		$G --abstract-type-refining $G --code-folding $G --const-hoisting $G --dae $G --flatten $G --dfo $G --merge-locals $G --merge-similar-functions --type-finalizing \
		$G --type-unfinalizing $G --type-ssa $G -O4 $G --flatten $G --rereloop $G -O4 $G -O4 $G --type-merging $G --type-finalizing $G -O4 \
		$G --type-unfinalizing $G --type-ssa $G -Oz $G --flatten $G --rereloop $G -Oz $G -Oz $G --type-merging $G --type-finalizing $G -Oz 
)

mkdir -p dist/

cp rewriter/wasm/out/optimized.wasm dist/scramjet.wasm.wasm
{

cat <<EOF
if ("document" in self && document?.currentScript) {
	document.currentScript.remove();
}
EOF
echo -n "self.WASM = '"
base64 -w0 < "rewriter/wasm/out/optimized.wasm"
echo -n "';"

} > dist/scramjet.wasm.js
echo "Rewriter Build Complete!"
