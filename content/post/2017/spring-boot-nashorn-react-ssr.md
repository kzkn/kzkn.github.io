+++
date = "2017-04-13T00:03:07+09:00"
title = "Spring Boot + Nashorn + React + SSR"
draft = false

+++

表題のようなことをやってみたという話。以下のブログ記事をおおいに参考にさせていただいている。

[Ruby on Rails on React on SSR on SPA](http://r7kamura.hatenablog.com/entry/2016/10/10/173610)

# ソースの構成 #

Maven で作ったフォルダ構成に、フロントエンド用のソースを置く場所をつくっている。

```
$ tree .
tree .
.
├── pom.xml
├── src
│   ├── main
│   │   ├── frontend
│   │   │   ├── package.json
│   │   │   ├── src
│   │   │   │   ├── AutomatedCurrentTime.js
│   │   │   │   ├── CurrentTime.js
│   │   │   │   ├── Link.js
│   │   │   │   ├── Router.js
│   │   │   │   ├── client.js
│   │   │   │   ├── http.js
│   │   │   │   └── server.js
│   │   │   └── webpack.config.js
│   │   ├── java
│   │   │   └── org
│   │   │       └── genva
│   │   │           └── ssrpoc
│   │   │               └── App.java
│   │   └── resources
│   │       ├── application.yml
│   │       ├── static
│   │       │   └── js
│   │       │       └── polyfill.js
│   │       └── templates
│   │           ├── layout.html
│   │           └── test.html
│   └── test
│       └── java
└── target
    └── classes
        └── static
            └── js
                ├── client.bundle.js
                └── server.bundle.js

18 directories, 17 files
```

# java のビルド #

`mvn eclipse:eclipse` とか m2e とかで Eclipse にプロジェクトを読み込んで開発する。特に変わったところはない。

# js のビルド #

npm を使う。個別にインストールしてもいいし、[frontend-maven-plugin](https://github.com/eirslett/frontend-maven-plugin) のような maven に統合する仕組みもある。今回は独自にインストールした npm を使った。frontend-maven-plugin を使うと node や npm が target 配下に自動的にインストールされる。多少は導入が楽になると思う。

ビルドは `npm run watch` を裏で走らせるようにした。webpack のファイル監視機能を使って、ファイルが修正されたら自動的にビルドする。package.json はこんな感じ:


```
{
  "name": "ssrpoc-frontend",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "watch": "webpack -d -w",
    "dev-build": "webpack -d --display-modules"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "react": "^15.4.2",
    "react-dom": "^15.4.2",
    "react-helmet": "^5.0.2"
  },
  "devDependencies": {
    "babel-core": "^6.24.0",
    "babel-loader": "^6.4.1",
    "babel-preset-es2015": "^6.24.0",
    "babel-preset-react": "^6.23.0",
    "webpack": "^2.3.3"
  }
}
```

出力先をクラスパスの通った target/classes 配下にすることで、Eclipse で起動した java プログラムからも、自動的にその修正内容が見えるようになっている。出力先の設定は webpack.config.js に書く。webpack.config.js はこんな感じ:

```
var path = require('path');

module.exports = {
  entry: {
    client: './src/client.js',
    server: './src/server.js',
  },
  output: {
    path: path.resolve(__dirname, '../../../target/classes/static/js'),
    filename: '[name].bundle.js',
  },
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        include: [
          path.resolve(__dirname, './src')
        ],
        loader: 'babel-loader',
        query: {
          presets: ['es2015', 'react']
        }
      }
    ]
  }
};
```

# js の構成 #

js のエントリポイントは client.js と server.js のふたつを用意した。それぞれ、client.js はブラウザから、server.js はサーバーで SSR するときに読まれるスクリプトとしている。内容はほとんど一緒で、react-dom の render を使う (client.js) か、react-dom/server の renderToString を使う (server.js) かの差ぐらいしかない。

以下は server.js の中身 (原文ママ):

```
import React from 'react';
import { renderToString } from 'react-dom/server';
import Router from './Router';
import Helmet from 'react-helmet';

const components = {
  Router,
};

window.render = (component, props) => {
  if (components[component]) {
    const Component = components[component];
    const html = renderToString(<Component {...props} />);
    window.helmetTitle = Helmet.rewind().title.toString();
    return html;
  }
  else {
    throw "No available component: " + component;
  }
};
```

SSR するときには `window.render` を呼び出す。レンダリングしたいコンポーネントの名前と props を渡す。

http.js は XHR を使ってサーバーを叩く処理を書いたもの。特に変わったところはないので紹介は省く。

あと JS ファイルは React のコンポーネントを定義している。Router や Link は、[参考ページ](http://r7kamura.hatenablog.com/entry/2016/10/10/173610) にあるそれと似たような方針で作っている。

# Spring の設定  #

ここが一番苦労した。Spring で

 * 一発目は SSR
 * 以後は JSON だけをやり取りして CSR

というのを透過的にやりたい場合、ある程度の道具を自分で用意する必要がある。またそれを Spring にうまく統合する必要がある。

## ViewResolver ##

一発目は html, 二発目以降は json という要望に答えるためには、クライアントサイドの協力が必要になる。二度目以降で json を求める際には、Accept ヘッダに application/json と設定するようにする。サーバーはこのヘッダを見て、返す内容を切り替えるようにする。

Spring の ContentNegotiatingViewResolver がこの要求を満たすのにちょうどよかった。ContentNegotiatingViewResolver を以下のように設定した:

```
@Bean
public ContentNegotiatingViewResolver viewResolver(
        ThymeleafViewResolver thymeleafViewResolver,
        JsonViewResolver jsonViewResolver) {
    ContentNegotiatingViewResolver resolver = new ContentNegotiatingViewResolver();
    resolver.setViewResolvers(Arrays.asList(thymeleafViewResolver, jsonViewResolver));
    return resolver;
}
```

html 向けには ThymeleafViewResolver が提供する View を、json 向けには JsonViewResolver が提供する View を使うようになる。JsonViewResolver は独自に定義した ViewResolver で、以下のように定義している:

```
public static class JsonViewResolver extends AbstractCachingViewResolver {
    private final ObjectMapper mapper;

    public JsonViewResolver(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    @Override
    protected View loadView(String viewName, Locale locale) throws Exception {
        MappingJackson2JsonView view = new MappingJackson2JsonView(mapper);
        view.setContentType(MediaType.APPLICATION_JSON_VALUE);
        return view;
    }
}
```

ContentNegotiatingViewResolver に MappingJackson2JsonView が application/json 向けの View であることを知らせるため、必ず `setContentType` するようにしている。

## JavaScript Engine (Nashorn) ##

SSR では (当然) サーバーサイドで JavaScript のコードを走らせる必要がある。Java から使いやすいのは JRE に組み込まれている Nashorn なので、これを使う。

ScriptEngine の初期化、server.js の読み込みにはそれなりに時間がかかるので、インスタンスは使いまわしたい。しかし Nashorn はスレッドセーフではないので、スレッドをまたいでのインスタンスの共有は避けたいので、ThreadLocal に持ちたい。

また、ScriptEngine に読ませる server.js は、開発中はどんどん書き換えられる。かといって server.js を毎回読むのは遅すぎて辛い。なので、読み込んだときの server.js のタイムスタンプを覚えておき、更新された場合には自動的にリロードする仕組みを用意すると、開発が楽になる。

この辺を踏まえて、

 * Reload の仕組みを持つ ScriptEngine のラッパー
 * ↑を ThreadLocal に持つ Bean
 
を定義した。View は上記の Bean から取得したラッパーを通じて ScriptEngine を得る。この際、必要に応じて読み込み済みスクリプトのリロードを行う。

まずは前者の抜粋:

```
public static class RelodableScriptEngine {
    // 一部省略

    public void addScript(String script) {
        this.scripts.add(script);
        this.timestamps.put(script, -1L);
    }

    public ScriptEngine get() {
        return engine;
    }

    public RelodableScriptEngine reload() throws ScriptException, IOException {
        for (String script : scripts) {
            Resource resource = resourceLoader.getResource(script);
            long lastModified = resource.lastModified();
            if (timestamps.get(script) < lastModified) {
                engine.eval(new InputStreamReader(resource.getInputStream()), scriptBindings);
                timestamps.put(script, lastModified);
            }
        }

        return this;
    }
}
```

View で render する直前に reload して、以後は get だけの reload なしで ScriptEngine を取得するようにして使っている。reload が必要最低限に抑えられる。

次に後者の抜粋:

```
public static class ReloadableScriptEngineFactory implements ApplicationContextAware {

    private final ThreadLocal<RelodableScriptEngine> engines = new ThreadLocal<>();

    // 一部省略

    public RelodableScriptEngine getScriptEngine() throws Exception {
        RelodableScriptEngine e = engines.get();
        if (e != null)
            return e;

        ScriptEngine engine = scriptEngineManager.getEngineByName(engineName);
        e = new RelodableScriptEngine(engine, context);
        scripts.forEach(e::addScript);
        e.reload();  // initial load
        engines.set(e);
        return e;
    }
}
```

RelodableScriptEngine を ThreadLocal で保持るだけの、なんの変哲もないクラスである。自身が持つスクリプトファイルのリストを RelodableScriptEngine に受け渡し、ロードした上でインスタンスを返す。Bean の定義は以下のようにしている:

```
@Bean
public ReloadableScriptEngineFactory reloadableScriptEngineFactory() {
    ReloadableScriptEngineFactory factory = new ReloadableScriptEngineFactory();
    factory.addScript("classpath:/static/js/polyfill.js");
    factory.addScript("classpath:/static/js/server.bundle.js");
    return factory;
}
```

polyfill.js は Nashorn にない JavaScript のオブジェクトを定義する短いスクリプトである。ググると色々バリエーションが見つかるので、紹介はそちらに譲りたい。server.bundle.js は server.js を webpack したスクリプトである。

サーバーサイドで JS コードを実行する箇所のすべてでこの仕組みを使っている。

なお、Nashorn がスレッドセーフでないことは、以下から確認できる:

```
ScriptEngineManager sem = new ScriptEngineManager();
Optional<ScriptEngineFactory> factory = sem.getEngineFactories().stream()
        .filter(f -> f.getEngineName().equals("Oracle Nashorn"))
        .findFirst();
factory.ifPresent(f -> System.out.printf("nashorn threading: %s%n", f.getParameter("THREADING")));
```

実行すると `nashorn threading: null` と出力される。[Javadoc](http://docs.oracle.com/javase/8/docs/api/javax/script/ScriptEngineFactory.html#getParameter-java.lang.String-) によれば、`getParameter("THREADING")` で null が返ってくる場合は

> The engine implementation is not thread safe, and cannot be used to execute scripts concurrently on multiple threads. 

であるとのことなので、Nashorn は (現時点では) スレッドセーフではない。

## Thymeleaf テンプレートからサーバーサイド JS を叩く ##

Helmet などを使うにあたって、Thymeleaf のテンプレートから JS を叩けるようにしておくと便利なのであった。Thymeleaf にはそんな仕組みがないので、自前で用意する。Thymeleaf にはテンプレートエンジンを拡張するための仕組みが[用意されている](http://www.thymeleaf.org/doc/tutorials/3.0/extendingthymeleaf.html)ので、これを使う。

まず、どのように使うかを考える。こんな感じで使えるものを用意する:

```
<head>
  <title serverjs:replace="window.helmetTitle">Server Side Rendering - Proof of Concept</title>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
</head>
```

title 要素の `serverjs:replace` の部分が、用意したい部品である。JS 式を属性の値に渡して、その評価結果を要素としてまるごと置き換える。

```
public static class ServerJsReplaceAttrProcessor extends AbstractAttributeTagProcessor {
    private static final String ATTR_NAME = "replace";
    private static final int PRECEDENCE = 10000;

    private ReloadableScriptEngineFactory engineFactory;

    public ServerJsReplaceAttrProcessor(ReloadableScriptEngineFactory engineFactory, String dialectPrefix) {
        super(TemplateMode.HTML,  // this processor will apply only to HTML mode
                dialectPrefix,    // prefix to be applied to name for matching
                null,             // no tag name: match any tag name
                false,            // no prefix to be applied to tag name
                ATTR_NAME,        // name of the attribute that will be matched
                true,             // apply dialect prefix to attribute name
                PRECEDENCE,       // precedence (inside dialect's precedence)
                true);            // remove the matched attribute afterwards

        this.engineFactory = engineFactory;
    }

    @Override
    protected void doProcess(ITemplateContext context, IProcessableElementTag tag, AttributeName attributeName,
            String attributeValue, IElementTagStructureHandler structureHandler) {
        try {
            RelodableScriptEngine engine = engineFactory.getScriptEngine();
            Object val = engine.get().eval(attributeValue);
            structureHandler.replaceWith(String.valueOf(val), false);
        }
        catch (Exception e) {
            throw new TemplateProcessingException("failed to eval js: '" + attributeValue + "'", e);
        }
    }
}
```

Thymeleaf のチュートリアルのコピペっぽいところはご容赦いただきたい。事前に準備しておいた RelodableScriptEngine を使って属性値を評価し、要素をまるごと置き換えている。今回はまるごと置き換える用途でしか使うことがなかったのでこれだけだが、テキスト要素だけを設定するようにするとか、他にも IProcessor 実装のバリエーションはいくつか考えられる。

この ServerJsReplaceAttrProcessor を使えるようにするため、Dialect を用意する。

```
public static class ServerJsDialect extends AbstractProcessorDialect {
    private ReloadableScriptEngineFactory engineFactory;

    public ServerJsDialect(ReloadableScriptEngineFactory engineFactory) {
        super("ServerJsDialect", "serverjs", 1000);
        this.engineFactory = engineFactory;
    }

    @Override
    public Set<IProcessor> getProcessors(String dialectPrefix) {
        Set<IProcessor> procs = new HashSet<>();
        procs.add(new ServerJsReplaceAttrProcessor(engineFactory, dialectPrefix));
        return procs;
    }
}
```

特に疑問点はない。あとはこれを Bean 定義すれば、Thymeleaf の autoconfigure によって自動的にテンプレートエンジンへ登録される。

## SSR の実行とテンプレートへの埋め込み ##

ServerJsDialect によって Thymeleaf テンプレート内で JS 式を評価できるようになった。しかし、例えば Helmet を使ってタイトルを得るには、React によるレンダリングを行ったあとで式を評価しなければならない。なので、事前に React を実行しておいて、それを埋め込むのはテンプレートへの引数などを利用しつつ、そのエンジンの状態は `serverjs:replace` の実行まで保持するようにしたい。また、次のレンダリング実行時には、エンジンはある程度まっさらな状態に戻したい。しかし server.js を読み込みなおすのはパフォーマンスへの影響が大きいので、これを考慮する必要もある。

といったちょっと込み入った要望に答えるため、以下のような実装とした。ThymeleafView を拡張し、render 前に SSR を実行、model にレンダリング結果を保持する。テンプレート側のどこかで `th:utext="${react_component}"` を埋め込めば、レンダリング結果を展開することができる。

```
public static class ServerJsThymeleafView extends ThymeleafView {
    public static final String KEY_PROPS = "props";
    public static final String KEY_REACT_COMPONENT = "react_component";
    
    // コンストラクタ、initApplicationContext は省略

    @Override
    public void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        RelodableScriptEngine engine = engineFactory.getScriptEngine().reload().newBindings();
        model = renderReactComponent(model, engine.get());
        super.render(model, request, response);
    }

    private Map<String, ?> renderReactComponent(Map<String, ?> model, ScriptEngine engine) throws Exception {
        Map<String, Object> map = new HashMap<>();
        if (model != null)
            map.putAll(model);

        String html = react.render(engine, "Router", (String) map.get(KEY_PROPS));
        map.put(KEY_REACT_COMPONENT, html);

        return map;
    }
}

public static class ReactComponent {
    public String render(ScriptEngine engine, String component, String props) throws Exception {
        Object html = engine.eval("render('" + component + "', " + props + ")");
        return String.valueOf(html);
    }
}
```

エンジンの状態を (ある程度) リセットするために、ReloadableScriptEngine に newBindings というメソッドを用意している。ReloadableScriptEngine.reload したときに使った Bindings のコピーを作って ScriptEngine に設定するというメソッドである。SSR の実行ではこの Bindings を使うことで、scripts の読み込み結果以外の状態を、まっさらに戻すことができる。

```
public static class RelodableScriptEngine {
    // 一部省略
    public RelodableScriptEngine newBindings() {
        this.engine.setBindings(new SimpleBindings(scriptBindings), ScriptContext.ENGINE_SCOPE);
        return this;
    }
}
```

Thymeleaf のテンプレート (layout.html) は、結局こうなった:

```
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
  <head>
    <title serverjs:replace="window.helmetTitle">Server Side Rendering - Proof of Concept</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  </head>
  <body>
    <div id="app" th:utext="${react_component}"></div>

    <script th:src="@{/js/client.bundle.js}"></script>
    <script th:inline="javascript">
    (function() {
        var props = /*[(${props})]*/ { now: '' };
        window.render('Router', props, document.getElementById('app'));
    })();
    </script>
  </body>
</html>
```

## Router による Routing の判断材料を用意する ##

[くだんの記事](http://r7kamura.hatenablog.com/entry/2016/10/10/173610) では `actionPath` と呼ばれているものを用意する。はじめは View の名前を使えばいいんじゃないかと思ったが、View (Thymeleaf テンプレート) はほぼ同じものを共通して使うことになりそうなので、具合が悪い。記事にならって actionPath に相当する文字列を用意することにした。

```
public static class ReactAttrsInterceptor extends HandlerInterceptorAdapter {
    private ObjectMapper mapper;

    public ReactAttrsInterceptor(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
            ModelAndView modelAndView) throws Exception {
        if (modelAndView != null) {
            ModelMap model = modelAndView.getModelMap();
            model.addAttribute("actionPath", buildActionPath(handler, modelAndView));
            if (!isJson(request)) {
                if (modelAndView.getViewName().isEmpty())
                    modelAndView.setViewName("layout");
                model.addAttribute("props", mapper.writeValueAsString(model));
            }
        }
    }

    private String buildActionPath(Object handler, ModelAndView mav) {
        if (handler instanceof HandlerMethod) {
            return buildActionPath((HandlerMethod) handler);
        }
        else {
            System.err.println("Unsupported handler: " + (handler != null ? handler.getClass() : "null"));
            return "";
        }
    }

    private String buildActionPath(HandlerMethod handler) {
        String typeName = handler.getBeanType().getSimpleName();
        if (typeName.endsWith("Controller"))
            typeName = typeName.substring(0, typeName.length() - "Controller".length());

        String methodName = handler.getMethod().getName();
        return typeName + "#" + methodName;
    }

    private boolean isJson(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        if (accept != null)
            return accept.contains("application/json");
        else
            return false;
    }
}
```

ハンドラのクラスが `IndexController`、メソッドが `show` なら `Index#show` にする、といった適当な実装である。とりあえずこれでも動く、というレベル。

なお、この実装では他にも作り込みがある。html が求められている (`Accept: application/json` ではない) 場合には、モデルの内容を JSON 化した文字列を `props` としてモデルに追加している。これは SSR で React に食わせる props となる。JSON が求められている場合にはモデルをそのまま JSON 化してしまえば同じものが得られるので必要ない。

このインターセプタを Spring MVC に認識させるよう設定する:

```
@Configuration
public static class WebConfig extends WebMvcConfigurerAdapter {
    @Autowired
    private ObjectMapper mapper;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new ReactAttrsInterceptor(mapper));
    }
}
```

## 残りのタスク、ソース ##

あとはコントローラを書いたり main メソッドを書いたりする程度のことやれば、どうにかこうにか動く状態になる。

すでにこのページでほぼ全体のソースを挙げているが、一部は省略していたりする。省略のないソース全体は [Github](https://github.com/kzkn/spring-ssr-poc) にアップしている。

# まとめ #

サーバーサイドである程度の苦労が必要だった。そしてそのわりにはあまり満足の行くパフォーマンスは得られず、個人的には、これを実用するのは難しいと感じている。とはいうものの SSR 自体の価値がないわけではない。Node を使うなどの、別の方法を模索したい。
