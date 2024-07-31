import { ScramjetBootstrapper } from "./bootsrapper/index";
import { encodeUrl, decodeUrl } from "./shared/rewriters/url";
import { rewriteCss } from "./shared/rewriters/css";
import { rewriteHtml, rewriteSrcset } from "./shared/rewriters/html";
import { rewriteJs } from "./shared/rewriters/js";
import { rewriteHeaders } from "./shared/rewriters/headers";
import { rewriteWorkers } from "./shared/rewriters/worker";
import { isScramjetFile } from "./shared/rewriters/html";
import type { Codec } from "./codecs";
import { BareClient } from "@mercuryworkshop/bare-mux";
import { parseDomain } from "parse-domain";

interface ScramjetConfig {
	prefix: string;
	codec: string;
	wrapfn: string;
	trysetfn: string;
	importfn: string;
	rewritefn: string;
	shared: string;
	worker: string;
	thread: string;
	client: string;
	codecs: string;
}

declare global {
	interface Window {
		$scramjet: {
			shared: {
				url: {
					encodeUrl: typeof encodeUrl;
					decodeUrl: typeof decodeUrl;
				};
				rewrite: {
					rewriteCss: typeof rewriteCss;
					rewriteHtml: typeof rewriteHtml;
					rewriteSrcset: typeof rewriteSrcset;
					rewriteJs: typeof rewriteJs;
					rewriteHeaders: typeof rewriteHeaders;
					rewriteWorkers: typeof rewriteWorkers;
				};
				util: {
					BareClient: typeof BareClient;
					isScramjetFile: typeof isScramjetFile;
					parseDomain: typeof parseDomain;
				};
			};
			config: ScramjetConfig;
			codecs: {
				none: Codec;
				plain: Codec;
				base64: Codec;
				xor: Codec;
			};
			codec: Codec;
		};
		WASM: string;
		ScramjetBootstrapper: typeof ScramjetBootstrapper;
	}
}
