import {
	Config,
	ParameterValue,
	RouteName,
	RouteParams,
	Router,
} from "../../../vendor/tightenco/ziggy/src/js";

declare global {
	interface Global {
		route: {
			(): Router;
			<T extends RouteName>(
				name: T,
				params?: RouteParams<T> | undefined,
				absolute?: boolean | undefined,
				config?: Config | undefined,
			): string;
			<T extends RouteName>(
				name: T,
				params?: ParameterValue | undefined,
				absolute?: boolean | undefined,
				config?: Config | undefined,
			): string;
			(
				name: undefined,
				params: undefined,
				absolute: boolean,
				config?: Config | undefined,
			): string;
		};
	}
}
