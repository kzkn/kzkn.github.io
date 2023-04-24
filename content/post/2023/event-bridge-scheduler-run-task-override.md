---
title: "EventBridge Scheduler で RunTask するときにタスク定義をオーバーライドする方法"
date: 2023-04-24T12:30:29+09:00
draft: false
---

表題の How To 記事です。内容的には[2023/4/2](/post/2023/2023-04-24/)の日記に書いていたものとほぼ同じだけど、たどり着きやすいように独立した記事にしておく。

---

例えば Rails アプリにおける定期実行を EventBridge Scheduler から RunTask する形で組む場合、処理の種類ごとにタスク定義を用意するのは煩雑だと思う。だいたいの場合は、アプリケーション本体のために用意したタスク定義のコマンドを上書きするだけでよいはず。例えば `lib/cron.rake` に定期実行するタスクを書いておいて、コンテナのコマンドとして `bin/rake cron:my_task`, `bin/rake cron:my_task_2` を指定する感じ。

また、処理の種類によってはタスク実行基盤に用意させるリソースを増やしたり減らしたりしたいかもしれない。

一言で言えば、EventBridge Scheduler から RunTask する際に、[aws ecs run-task](https://docs.aws.amazon.com/cli/latest/reference/ecs/run-task.html) の `--overrides` 相当のパラメータを指定したい。

これを実現する方法にたどり着くのに苦労した。[create_schedule](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Scheduler/Client.html#create_schedule-instance_method) の [ecs_parameters](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Scheduler/Types/EcsParameters.html) には `override` や `containerOverrides` の項目がない。ではどうするかというと、[input](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Scheduler/Types/Target.html#input-instance_method) という項目に `override` 相当の JSON 文字列を突っ込む。例えばこんな感じ(関係ない部分は省略):

```
create_schedule({
  target: {
    ecs_parameters: {
      task_definition_arn:,
    },
    input: { cpu: '512', containerOverrides: [{ name: 'app', command: %w[echo hello] }] }.to_json
  },
})
```

これでタスク定義の CPU を 512 に、`app` コンテナのコマンドを `["echo", "hello"]` にオーバーライドできる。
