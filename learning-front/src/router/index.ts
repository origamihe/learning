import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { title: '登录', requiresAuth: false },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/views/RegisterView.vue'),
      meta: { title: '注册', requiresAuth: false },
    },
    // 主布局（含 TopNav）
    {
      path: '/',
      component: () => import('@/views/MainLayout.vue'),
      children: [
        {
          path: '',
          redirect: '/home',
        },
        {
          path: 'home',
          name: 'home',
          component: () => import('@/views/HomeView.vue'),
          meta: { title: '首页', requiresAuth: true },
        },
        {
          path: 'courses',
          name: 'courses',
          component: () => import('@/views/CourseListView.vue'),
          meta: { title: '课程列表', requiresAuth: true },
        },
        {
          path: 'courses/:id/practice',
          name: 'questionPractice',
          component: () => import('@/views/QuestionPracticeView.vue'),
          meta: { title: '章节练习', requiresAuth: true },
        },
        {
          path: 'courses/:id',
          name: 'courseDetail',
          component: () => import('@/views/CourseDetailView.vue'),
          meta: { title: '课程详情', requiresAuth: true },
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('@/views/ProfileView.vue'),
          meta: { title: '个人中心', requiresAuth: true },
        },
        {
          path: 'wrong-book',
          name: 'wrongBook',
          component: () => import('@/views/WrongQuestionBookView.vue'),
          meta: { title: '错题本', requiresAuth: true },
        },
        // 管理员路由
        {
          path: 'admin/dashboard',
          name: 'adminDashboard',
          component: () => import('@/views/admin/Dashboard.vue'),
          meta: { title: '管理后台', requiresAuth: true, requiresAdmin: true },
        },
        {
          path: 'admin/users',
          name: 'adminUsers',
          component: () => import('@/views/admin/UserManage.vue'),
          meta: { title: '用户管理', requiresAuth: true, requiresAdmin: true },
        },
        {
          path: 'admin/courses',
          name: 'adminCourses',
          component: () => import('@/views/admin/CourseManage.vue'),
          meta: { title: '课程管理', requiresAuth: true, requiresAdmin: true },
        },
        {
          path: 'admin/sections',
          name: 'adminSections',
          component: () => import('@/views/admin/SectionManage.vue'),
          meta: { title: '章节管理', requiresAuth: true, requiresAdmin: true },
        },
        {
          path: 'admin/questions',
          name: 'adminQuestions',
          component: () => import('@/views/admin/QuestionManage.vue'),
          meta: { title: '题目管理', requiresAuth: true, requiresAdmin: true },
        },
        {
          path: 'admin/exams',
          name: 'adminExams',
          component: () => import('@/views/admin/ExamManage.vue'),
          meta: { title: '考试管理', requiresAuth: true, requiresAdmin: true },
        },
      ],
    },
  ],
})

// 路由守卫 - JWT 鉴权
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  const requiresAuth = to.meta.requiresAuth as boolean
  const requiresAdmin = to.meta.requiresAdmin as boolean

  if (requiresAuth && !authStore.isLoggedIn) {
    next('/login')
    return
  }

  if (requiresAdmin && !authStore.isAdmin) {
    next('/home')
    return
  }

  if ((to.path === '/login' || to.path === '/register') && authStore.isLoggedIn) {
    next(authStore.isAdmin ? '/admin/dashboard' : '/home')
    return
  }

  next()
})

export default router
