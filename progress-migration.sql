-- 任务进度字段迁移
-- 在 Supabase SQL Editor 中执行此脚本。
-- 如果前端报错 PGRST204: Could not find the 'progress' column，
-- 通常是 PostgREST schema cache 还没有刷新，脚本末尾会主动刷新。

-- 检查 public.tasks 表是否存在，如果不存在则创建
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'tasks'
  ) THEN
    -- 创建任务表
    CREATE TABLE public.tasks (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'done')),
      priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
      progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
      due_date DATE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- 启用 RLS
    ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

    -- 创建 RLS 策略
    CREATE POLICY "Allow all operations on tasks" ON public.tasks
      FOR ALL USING (true) WITH CHECK (true);

    -- 创建索引
    CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
    CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);

    RAISE NOTICE 'public.tasks 表已创建';
  ELSE
    RAISE NOTICE 'public.tasks 表已存在';
  END IF;
END $$;

-- 添加 progress 字段
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100);

-- 修复旧数据，确保已有任务也有默认进度
UPDATE public.tasks SET progress = 0 WHERE progress IS NULL;

-- 刷新 Supabase REST(PostgREST) 的 schema cache。
-- 否则表编辑器里能看到 progress，但前端 PATCH 仍可能返回 PGRST204。
NOTIFY pgrst, 'reload schema';

-- 如果 PostgREST 没收到上面的通知，Supabase 官方建议执行此查询来推动通知队列刷新。
SELECT pg_notification_queue_usage() AS notification_queue_usage;

-- 完成提示
DO $$
BEGIN
  RAISE NOTICE '进度字段迁移完成！如果刚才有 PGRST204，请刷新页面后再试。';
END $$;

-- 诊断结果：执行后应该返回 1 行 progress / integer。
SELECT
  table_schema,
  table_name,
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'tasks'
  AND column_name = 'progress';
