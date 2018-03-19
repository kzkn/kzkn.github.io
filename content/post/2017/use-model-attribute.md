+++
date = "2017-09-19T21:53:03+09:00"
title = "@ModelAttribute を使う"
draft = false

+++

Spring 関連の小ネタで、[@ModelAttribute](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ModelAttribute.html) を使おう、という話。当たり前に使われているからか、私の探し方が悪いからか、「活用しよう」という記事をあまり見た覚えがないわりに、わりと便利に使えるので紹介したい。

---

# @ModelAttribute の動き #

`@ModelAttribute` アノテーションは、コントローラのメソッドか引数につけて使う。いずれの場合も、ハンドラメソッドが動く前にアノテーションが検出され、メソッドについているか、引数についているかに応じて、Spring によって処理される。

メソッドについている場合、Spring がハンドラメソッドを呼ぶ前に、`@ModelAttribute` つきのメソッドを呼び出す。Spring は、その戻り値を [Model](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/ui/Model.html) に詰める。`Model` に詰める際のキー (名前) は、`@ModelAttribute.name` で指定する。未指定の場合は戻り値のオブジェクトのクラス名から自動生成されたものになる。

引数についている場合、Spring がハンドラメソッドを呼ぶ前に、その引数につけられた `@ModelAttribute.name` に対応するオブジェクトを `Model` から探す。`Model` に該当するオブジェクトがなければ、そのタイミングで `new` する。引数のオブジェクトが用意できたら、Spring はそのオブジェクトに対してリクエストボディのバインディングを行う。そうして用意されたオブジェクトが、ハンドラメソッドのオブジェクトとして渡される。バインディングを行いたくない場合は `@ModelAttribute.binding` に `false` を設定する。

# @ModelAttribute の用途 #

かんたんな動きを抑えたところで、`@ModelAttribute` の具体的な使い方をいくつか介したい。

## リクエストボディの内容を受け取る ##

ど定番の使い方。POST で送られてくるリクエストボディの内容を、オブジェクトにバインディングするというもの。ハンドラメソッドの引数に `@ModelAttribute` をつける。特に説明する点はない。

## 全ハンドラメソッドに共通するオブジェクトを作る ##

例えばこんなコントローラがあったとする:

```java
@Controller
@RequestMapping("/")
public class HomeController {

  @GetMapping
  public String index(Model model) {
    model.addAttribute("menu", findMenuForCurrentUser());
    return "top";
  }
  
  @GetMapping
  public String sitemap(Model model) {
    model.addAttribute("menu", findMenuForCurrentUser());
    return "sitemap";
  }
}
```

このコントローラでは全ハンドラメソッド (といっても 2 つしかないが) で `"menu"` という Attribute を詰めている。`@ModelAttribute` を使えば、これを DRY にできる。

```java
@ModelAttribute
public Menu getMenu() {
  return findMenuForCurrentUser();
}

@GetMapping
public String index() {
  return "top";
}

@GetMapping
public String sitemap() {
  return "sitemap";
}
```

`findMenuForCurrentUser` の結果を `Model` に突っ込む処理が、`@ModelAttribute` を使うことで `getMenu` に集約されている。

## 全ハンドラメソッドに共通するオブジェクトを作る - その 2 ##

URL の一部をエンティティの ID とし、URL 内の ID から対象となるエンティティを検索して処理をする。なんていう設計は、よくあると思う。`@ModelAttribute` を使うと、これも DRY にできる。

```java
@Controller
@RequestMapping("/posts/{id}")
public class PostController {
  @ModelAttribute
  public Post getPost(@PathVariable long id) {
    return findPostById(id);
  }
  
  @GetMapping
  public String show() {
    return "show";
  }
  
  @GetMapping("/edit")
  public String edit() {
    return "edit";
  }
  
  @PutMapping
  public String update(@ModelAttribute Post post, BindingResult results) {
    // ...
    return "redirect:/posts/" + post.id;
  }
}
```

ここでは URL 内の ID から Post というエンティティを探してくる処理を `@ModelAttribute` つきのメソッドで実装した。`@ModelAttribute` つきのメソッドでは、ハンドラメソッドと同じような引数を受け取ることができるので、`@PathVariable` をメソッドの引数につけることができる。

ハンドラメソッド `update` では引数にも `@ModelAttribute` をつけているので、バインディングが行われる。このときバインディングする対象となるのは、`getPost` の戻り値のオブジェクトとなる (引数のオブジェクトを `Model` から探すから)。

## 存在チェック ##

URL の一部をエンティティの ID とし、URL 内の ID から対象となるエンティティを検索して処理をする。エンティティが見つからない場合は 404 とする。なんていう設計は、よくあると思う。`@ModelAttribute` を使うと、これも DRY にできる。先の例の `getPost` を修正する。

```java
@ModelAttribute
public Post getPost(@PathVariable long id) {
  return findPostById(id).orElseThrow(NotFoundException::new);
}
```

ここでは Post が見つからなければ `NotFoundException` (という例外が Spring に用意されているわけではない) を投げるようにした。`@ModelAttribute` つきのメソッドは常にハンドラメソッドより前に呼び出されるので、Post が見つからなければハンドラメソッドに入る前に例外が飛ぶので、リクエストをエラーとすることができる。`NotFoundException` を 404 にひもづける実装は [@ExceptionHandler](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ExceptionHandler.html) や [@ResponseStatus](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ResponseStatus.html) で行うとよい。

## パラメータの前処理 ##

例えば送られてくるクエリパラメータを正規化するとか。

```java
@Controller
@RequestMapping("/search")
public class SearchController {
  @ModelAttribute(name = "query")
  public String normalize(@RequestParam String q) {
    return Normalizer.normalize(q, Normalizer.Form.NFKC);
  }

  @GetMapping("/users")
  public String searchUsers(@ModelAttribute(name = "query", binding = false) String query, Model model) {
    model.addAttribute("users", searchUsersByQuery(query));
    return "searchUsers";
  }
  
  @GetMapping("/posts")
  public String searchPosts(@ModelAttribute(name = "query", binding = false) String query, Model model) {
    model.addAttribute("posts", searchPostsByQuery(query));
    return "searchPosts";
  }
}
```

基本的な原理はこれまで解説してきた通り。`@ModelAttribute.binding` を使うことで、リクエストボディのバインディングを行わないよう Spring に伝えている。今回は扱っているオブジェクトが `String` なので特に問題はないが、独自の (mutable な) クラスで、かつバインディング不要な引数に `binding=false` を付け忘れると、予期しないバインディングが行われた結果、バグを作りこむかもしれない。バインディングが不要なら、指定が必須 (= 指定しなきゃ動かない) かどうかにかかわらず、おとなしく `binding=false` をつけておくのが無難だと思う。

---

とまぁ、色々便利といったわりには例が少なくなってしまったのだけど、POST のボディをバインディングする以外にも使い道があるよ、というお話でした。
